#
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from code import interact
from distutils.command.config import config
import os
from pickletools import int4
import time
from collections import defaultdict
from google.cloud import monitoring_v3, asset_v1
from google.protobuf import field_mask_pb2
from googleapiclient import discovery
from metrics import ilb_fwrules, instances, networks, metrics, limits, peerings

config = {
  # Organization ID containing the projects to be monitored
  "organization": os.environ.get("ORGANIZATION_ID"),
  # list of projects from which function will get quotas information
  "monitored_projects": os.environ.get("MONITORED_PROJECTS_LIST").split(","),
  "monitoring_project_link": os.environ.get('MONITORING_PROJECT_ID'),
  "monitoring_project_link":f"projects/{os.environ.get('MONITORING_PROJECT_ID')}",
  "limit_names": {
      "GCE_INSTANCES": "compute.googleapis.com/quota/instances_per_vpc_network/limit",
      "L4": "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit",
      "L7": "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/limit",
      "SUBNET_RANGES": "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/limit"
  },
  "lb_scheme": {
    "L7": "INTERNAL_MANAGED",
    "L4": "INTERNAL"
  },
  "clients": {
    "discovery_client": discovery.build('compute', 'v1'),
    "asset_client":  asset_v1.AssetServiceClient()
  }
}

def main(event, context):
  '''
    Cloud Function Entry point, called by the scheduler.

      Parameters:
        event: Not used for now (Pubsub trigger)
        context: Not used for now (Pubsub trigger)
      Returns:
        'Function executed successfully'
  '''

  metrics_dict, limits_dict = metrics.create_metrics(config["monitoring_project_link"])

  # Asset inventory queries
  gce_instance_dict = instances.get_gce_instance_dict(config)
  l4_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L4")
  l7_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L7")
  subnet_range_dict = networks.get_subnet_ranges_dict(config)

  # Per Network metrics
  instances.get_gce_instances_data(config, metrics_dict, gce_instance_dict,
                         limits_dict['number_of_instances_limit'])
  ilb_fwrules.get_forwarding_rules_data(
      config, metrics_dict, l4_forwarding_rules_dict,
      limits_dict['internal_forwarding_rules_l4_limit'], "L4")
  ilb_fwrules.get_forwarding_rules_data(
    config, metrics_dict, l7_forwarding_rules_dict,
      limits_dict['internal_forwarding_rules_l7_limit'], "L7")
  peerings.get_vpc_peering_data(config, metrics_dict,
                       limits_dict['number_of_vpc_peerings_limit'])
  dynamic_routes_dict = get_dynamic_routes(
      metrics_dict, limits_dict['dynamic_routes_per_network_limit'])

  # Per VPC peering group metrics
  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]["instance_per_peering_group"],
      gce_instance_dict, config["limit_names"]["GCE_INSTANCES"],
      limits_dict['number_of_instances_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["l4_forwarding_rules_per_peering_group"], l4_forwarding_rules_dict,
      config["limit_names"]["L4"],
      limits_dict['internal_forwarding_rules_l4_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["l7_forwarding_rules_per_peering_group"], l7_forwarding_rules_dict,
      config["limit_names"]["L7"],
      limits_dict['internal_forwarding_rules_l7_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["subnet_ranges_per_peering_group"], subnet_range_dict,
      config["limit_names"]["SUBNET_RANGES"],
      limits_dict['number_of_subnet_IP_ranges_ppg_limit'])

  get_dynamic_routes_ppg(
      metrics_dict["metrics_per_peering_group"]
      ["dynamic_routes_per_peering_group"], dynamic_routes_dict,
      limits_dict['number_of_subnet_IP_ranges_ppg_limit'])

  return 'Function executed successfully'

#########################################################

def create_client():
  '''
    Creates the monitoring API client, that will be used to create, read and update custom metrics.

      Parameters:
        None
      Returns:
        client (monitoring_v3.MetricServiceClient): Monitoring API client
        interval (monitoring_v3.TimeInterval): Interval for the metric data points (24 hours)
  '''
  try:
    client = monitoring_v3.MetricServiceClient()
    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10**9)
    interval = monitoring_v3.TimeInterval({
        "end_time": {
            "seconds": seconds,
            "nanos": nanos
        },
        "start_time": {
            "seconds": (seconds - 86400),
            "nanos": nanos
        },
    })
    return (client, interval)
  except Exception as e:
    raise Exception("Error occurred creating the client: {}".format(e))

def get_pgg_data(metric_dict, usage_dict, limit_metric, limit_dict):
  '''
    This function gets the usage, limit and utilization per VPC peering group for a specific metric for all projects to be monitored.

      Parameters:
        metric_dict (dictionary of string: string): Dictionary with the metric names and description, that will be used to populate the metrics
        usage_dict (dictionnary of string:int): Dictionary with the network link as key and the number of resources as value
        limit_metric (string): Name of the existing GCP metric for limit per VPC network
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        None
  '''
  for project in config["monitored_projects"]:
    network_dict_list = peerings.gather_peering_data(config, project)
    # Network dict list is a list of dictionary (one for each network)
    # For each network, this dictionary contains:
    #   project_id, network_name, network_id, usage, limit, peerings (list of peered networks)
    #   peerings is a list of dictionary (one for each peered network) and contains:
    #     project_id, network_name, network_id
    current_quota_limit = limits.get_quota_current_limit(f"projects/{project}",
                                                  limit_metric)
    if current_quota_limit is None:
      print(
          f"Could not write number of L7 forwarding rules to metric for projects/{project} due to missing quotas"
      )
      continue

    current_quota_limit_view = customize_quota_view(current_quota_limit)

    # For each network in this GCP project
    for network_dict in network_dict_list:
      if network_dict['network_id'] == 0:
        print(
            f"Could not write {metric_dict['usage']['name']} for peering group {network_dict['network_name']} in {project} due to missing permissions."
        )
        continue
      network_link = f"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{network_dict['network_name']}"

      limit = networks.get_limit_network(network_dict, network_link,
                                current_quota_limit_view, limit_dict)

      usage = 0
      if network_link in usage_dict:
        usage = usage_dict[network_link]

      # Here we add usage and limit to the network dictionary
      network_dict["usage"] = usage
      network_dict["limit"] = limit

      # For every peered network, get usage and limits
      for peered_network_dict in network_dict['peerings']:
        peered_network_link = f"https://www.googleapis.com/compute/v1/projects/{peered_network_dict['project_id']}/global/networks/{peered_network_dict['network_name']}"
        peered_usage = 0
        if peered_network_link in usage_dict:
          peered_usage = usage_dict[peered_network_link]

        current_peered_quota_limit = get_quota_current_limit(
            f"projects/{peered_network_dict['project_id']}", limit_metric)
        if current_peered_quota_limit is None:
          print(
              f"Could not write metrics for peering to projects/{peered_network_dict['project_id']} due to missing quotas"
          )
          continue

        peering_project_limit = customize_quota_view(current_peered_quota_limit)

        peered_limit = networks.get_limit_network(peered_network_dict,
                                         peered_network_link,
                                         peering_project_limit, limit_dict)
        # Here we add usage and limit to the peered network dictionary
        peered_network_dict["usage"] = peered_usage
        peered_network_dict["limit"] = peered_limit

      limits.count_effective_limit(config, project, network_dict, metric_dict["usage"]["name"],
                            metric_dict["limit"]["name"],
                            metric_dict["utilization"]["name"], limit_dict)
      print(
          f"Wrote {metric_dict['usage']['name']} for peering group {network_dict['network_name']} in {project}"
      )


def get_dynamic_routes_ppg(metric_dict, usage_dict, limit_dict):
  '''
    This function gets the usage, limit and utilization for the dynamic routes per VPC peering group.

      Parameters:
        metric_dict (dictionary of string: string): Dictionary with the metric names and description, that will be used to populate the metrics
        usage_dict (dictionnary of string:int): Dictionary with the network link as key and the number of resources as value
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        None
  '''
  for project in config["monitored_projects"]:
    network_dict_list = peerings.gather_peering_data(config, project)

    for network_dict in network_dict_list:
      network_link = f"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{network_dict['network_name']}"

      limit = limits.get_ppg(network_link, limit_dict)

      usage = 0
      if network_link in usage_dict:
        usage = usage_dict[network_link]

      # Here we add usage and limit to the network dictionary
      network_dict["usage"] = usage
      network_dict["limit"] = limit

      # For every peered network, get usage and limits
      for peered_network_dict in network_dict['peerings']:
        peered_network_link = f"https://www.googleapis.com/compute/v1/projects/{peered_network_dict['project_id']}/global/networks/{peered_network_dict['network_name']}"
        peered_usage = 0
        if peered_network_link in usage_dict:
          peered_usage = usage_dict[peered_network_link]

        peered_limit = limits.get_ppg(peered_network_link, limit_dict)

        # Here we add usage and limit to the peered network dictionary
        peered_network_dict["usage"] = peered_usage
        peered_network_dict["limit"] = peered_limit

      limits.count_effective_limit(config, project, network_dict, metric_dict["usage"]["name"],
                            metric_dict["limit"]["name"],
                            metric_dict["utilization"]["name"], limit_dict)
      print(
          f"Wrote {metric_dict['usage']['name']} for peering group {network_dict['network_name']} in {project}"
      )


def get_dynamic_routes(metrics_dict, limits_dict):
  '''
    Writes all dynamic routes per VPC to custom metrics.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions.
        limits_dict (dictionary of string: int): key is network link (or 'default_value') and value is the limit for that network
      Returns:
        dynamic_routes_dict (dictionary of string: int): key is network link and value is the number of dynamic routes for that network
  '''
  routers_dict = get_routers()
  dynamic_routes_dict = defaultdict(int)

  for project_id in config["monitored_projects"]:
    network_dict = networks.get_networks(config, project_id)

    for network in network_dict:
      sum_routes = get_routes_for_network(network['self_link'], project_id,
                                          routers_dict)
      dynamic_routes_dict[network['self_link']] = sum_routes

      if network['self_link'] in limits_dict:
        limit = limits_dict[network['self_link']]
      else:
        if 'default_value' in limits_dict:
          limit = limits_dict['default_value']
        else:
          print("Error: couldn't find limit for dynamic routes.")
          break

      utilization = sum_routes / limit

      metrics.write_data_to_metric(
          config, project_id, sum_routes, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["usage"]["name"],
          network['network_name'])
      metrics.write_data_to_metric(
          config, project_id, limit, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["limit"]["name"],
          network['network_name'])
      metrics.write_data_to_metric(
          config, project_id, utilization, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["utilization"]["name"],
          network['network_name'])

    print("Wrote metrics for dynamic routes for VPCs in project", project_id)

    return dynamic_routes_dict


def get_routes_for_network(network_link, project_id, routers_dict):
  '''
    Returns a the number of dynamic routes for a given network

      Parameters:
        network_link (string): Network self link.
        project_id (string): Project ID containing the network.
        routers_dict (dictionary of string: list of string): Dictionary with key as network link and value as list of router links.
      Returns:
        sum_routes (int): Number of routes in that network.
  '''
  sum_routes = 0

  if network_link in routers_dict:
    for router_link in routers_dict[network_link]:
      # Router link is using the following format:
      # 'https://www.googleapis.com/compute/v1/projects/PROJECT_ID/regions/REGION/routers/ROUTER_NAME'
      start = router_link.find("/regions/") + len("/regions/")
      end = router_link.find("/routers/")
      router_region = router_link[start:end]
      router_name = router_link.split('/routers/')[1]
      routes = get_routes_for_router(project_id, router_region, router_name)

      sum_routes += routes

  return sum_routes


def get_routes_for_router(project_id, router_region, router_name):
  '''
    Returns the same of dynamic routes learned by a specific Cloud Router instance

      Parameters:
        project_id (string): Project ID for the project containing the Cloud Router.
        router_region (string): GCP region for the Cloud Router.
        router_name (string): Cloud Router name.
      Returns:
        sum_routes (int): Number of dynamic routes learned by the Cloud Router.
  '''
  request = config["clients"]["discovery_client"].routers().getRouterStatus(project=project_id,
                                              region=router_region,
                                              router=router_name)
  response = request.execute()

  sum_routes = 0

  if 'result' in response:
    if 'bgpPeerStatus' in response['result']:
      for peer in response['result']['bgpPeerStatus']:
        sum_routes += peer['numLearnedRoutes']

  return sum_routes


def get_routers():
  '''
    Returns a dictionary of all Cloud Routers in the GCP organization.

      Parameters:
        None
      Returns:
        routers_dict (dictionary of string: list of string): Key is the network link and value is a list of router links.
  '''
  client = asset_v1.AssetServiceClient()

  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  routers_dict = {}

  response = client.search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/Router"],
          "read_mask": read_mask,
      })
  for resource in response:
    network_link = None
    router_link = None
    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "network":
          network_link = field_value
        if field_name == "selfLink":
          router_link = field_value

    if network_link in routers_dict:
      routers_dict[network_link].append(router_link)
    else:
      routers_dict[network_link] = [router_link]

  return routers_dict

def customize_quota_view(quota_results):
  '''
    Customize the quota output for an easier parsable output.

      Parameters:
        quota_results (string): Input from get_quota_current_usage or get_quota_current_limit. Contains the Current usage or limit for all networks in that project.
      Returns:
        quotaViewList (list of dictionaries of string: string): Current quota usage or limit.
  '''
  quotaViewList = []
  for result in quota_results:
    quotaViewJson = {}
    quotaViewJson.update(dict(result.resource.labels))
    quotaViewJson.update(dict(result.metric.labels))
    for val in result.points:
      quotaViewJson.update({'value': val.value.int64_value})
    quotaViewList.append(quotaViewJson)
  return quotaViewList


if __name__ == "__main__":
  main(None, None)
