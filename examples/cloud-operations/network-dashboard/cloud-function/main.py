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

import os
import time
import yaml
from collections import defaultdict
from google.api import metric_pb2 as ga_metric
from google.api_core import protobuf_helpers
from google.cloud import monitoring_v3, asset_v1
from google.protobuf import field_mask_pb2
from googleapiclient import discovery

# Organization ID containing the projects to be monitored
ORGANIZATION_ID = os.environ.get("ORGANIZATION_ID")
# list of projects from which function will get quotas information
MONITORED_PROJECTS_LIST = os.environ.get("MONITORED_PROJECTS_LIST").split(",")
# project where the metrics and dahsboards will be created
MONITORING_PROJECT_ID = os.environ.get("MONITORING_PROJECT_ID")
MONITORING_PROJECT_LINK = f"projects/{MONITORING_PROJECT_ID}"
service = discovery.build('compute', 'v1')

# Existing GCP metrics per network
GCE_INSTANCES_LIMIT_METRIC = "compute.googleapis.com/quota/instances_per_vpc_network/limit"
L4_FORWARDING_RULES_LIMIT_METRIC = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit"
L7_FORWARDING_RULES_LIMIT_METRIC = "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/limit"
SUBNET_RANGES_LIMIT_METRIC = "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/limit"


def main(event, context):
  '''
    Cloud Function Entry point, called by the scheduler.

      Parameters:
        event: Not used for now (Pubsub trigger)
        context: Not used for now (Pubsub trigger)
      Returns:
        'Function executed successfully'
  '''
  metrics_dict, limits_dict = create_metrics()

  # Asset inventory queries
  gce_instance_dict = get_gce_instance_dict()
  l4_forwarding_rules_dict = get_l4_forwarding_rules_dict()
  l7_forwarding_rules_dict = get_l7_forwarding_rules_dict()
  subnet_range_dict = get_subnet_ranges_dict()

  # Per Network metrics
  get_gce_instances_data(metrics_dict, gce_instance_dict, limits_dict['number_of_instances_limit'])
  get_l4_forwarding_rules_data(metrics_dict, l4_forwarding_rules_dict, limits_dict['internal_forwarding_rules_l4_limit'])
  get_vpc_peering_data(metrics_dict, limits_dict['number_of_vpc_peerings_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]["instance_per_peering_group"],
      gce_instance_dict, GCE_INSTANCES_LIMIT_METRIC, limits_dict['number_of_instances_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["l4_forwarding_rules_per_peering_group"], l4_forwarding_rules_dict,
      L4_FORWARDING_RULES_LIMIT_METRIC, limits_dict['internal_forwarding_rules_l4_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["l7_forwarding_rules_per_peering_group"], l7_forwarding_rules_dict,
      L7_FORWARDING_RULES_LIMIT_METRIC, limits_dict['internal_forwarding_rules_l7_ppg_limit'])

  get_pgg_data(
      metrics_dict["metrics_per_peering_group"]
      ["subnet_ranges_per_peering_group"], subnet_range_dict,
      SUBNET_RANGES_LIMIT_METRIC, limits_dict['number_of_subnet_IP_ranges_limit'])

  return 'Function executed successfully'


def get_l4_forwarding_rules_dict():
  '''
    Calls the Asset Inventory API to get all L4 Forwarding Rules under the GCP organization.

      Parameters:
        None
      Returns:
        forwarding_rules_dict (dictionary of string: int): Keys are the network links and values are the number of Forwarding Rules per network.
  '''
  client = asset_v1.AssetServiceClient()

  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  forwarding_rules_dict = defaultdict(int)

  response = client.search_all_resources(
      request={
          "scope": f"organizations/{ORGANIZATION_ID}",
          "asset_types": ["compute.googleapis.com/ForwardingRule"],
          "read_mask": read_mask,
      })
  for resource in response:
    internal = False
    network_link = ""
    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "loadBalancingScheme":
          internal = (field_value == "INTERNAL")
        if field_name == "network":
          network_link = field_value
    if internal:
      if network_link in forwarding_rules_dict:
        forwarding_rules_dict[network_link] += 1
      else:
        forwarding_rules_dict[network_link] = 1

  return forwarding_rules_dict


def get_l7_forwarding_rules_dict():
  '''
    Calls the Asset Inventory API to get all L7 Forwarding Rules under the GCP organization.

      Parameters:
        None
      Returns:
        forwarding_rules_dict (dictionary of string: int): Keys are the network links and values are the number of Forwarding Rules per network.
  '''
  client = asset_v1.AssetServiceClient()

  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  forwarding_rules_dict = defaultdict(int)

  response = client.search_all_resources(
      request={
          "scope": f"organizations/{ORGANIZATION_ID}",
          "asset_types": ["compute.googleapis.com/ForwardingRule"],
          "read_mask": read_mask,
      })
  for resource in response:
    internal = False
    network_link = ""
    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "loadBalancingScheme":
          internal = (field_value == "INTERNAL_MANAGED")
        if field_name == "network":
          network_link = field_value
    if internal:
      if network_link in forwarding_rules_dict:
        forwarding_rules_dict[network_link] += 1
      else:
        forwarding_rules_dict[network_link] = 1

  return forwarding_rules_dict


def get_gce_instance_dict():
  '''
    Calls the Asset Inventory API to get all GCE instances under the GCP organization.

      Parameters:
        None
      Returns:
        gce_instance_dict (dictionary of string: int): Keys are the network links and values are the number of GCE Instances per network.
  '''
  client = asset_v1.AssetServiceClient()

  gce_instance_dict = defaultdict(int)

  response = client.search_all_resources(
      request={
          "scope": f"organizations/{ORGANIZATION_ID}",
          "asset_types": ["compute.googleapis.com/Instance"],
      })
  for resource in response:
    for field_name, field_value in resource.additional_attributes.items():
      if field_name == "networkInterfaceNetworks":
        for network in field_value:
          if network in gce_instance_dict:
            gce_instance_dict[network] += 1
          else:
            gce_instance_dict[network] = 1

  return gce_instance_dict


def get_subnet_ranges_dict():
  '''
    Calls the Asset Inventory API to get all Subnet ranges under the GCP organization.

      Parameters:
        None
      Returns:
        subnet_range_dict (dictionary of string: int): Keys are the network links and values are the number of subnet ranges per network.
  '''
  client = asset_v1.AssetServiceClient()
  subnet_range_dict = defaultdict(int)
  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  response = client.search_all_resources(
      request={
          "scope": f"organizations/{ORGANIZATION_ID}",
          "asset_types": ["compute.googleapis.com/Subnetwork"],
          "read_mask": read_mask,
      })
  for resource in response:
    ranges = 0
    network_link = None

    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "network":
          network_link = field_value
          ranges += 1
        if field_name == "secondaryIpRanges":
          for range in field_value:
            ranges += 1

    if network_link in subnet_range_dict:
      subnet_range_dict[network_link] += ranges
    else:
      subnet_range_dict[network_link] = ranges

  return subnet_range_dict


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


def create_metrics():
  '''
    Creates all Cloud Monitoring custom metrics based on the metric.yaml file

      Parameters:
        None

      Returns:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
        limits_dict (dictionary of dictionary of string: int): limits_dict[metric_name]: dict[network_name] = limit_value
  '''
  client = monitoring_v3.MetricServiceClient()
  existing_metrics = []
  for desc in client.list_metric_descriptors(name=MONITORING_PROJECT_LINK):
    existing_metrics.append(desc.type)
  limits_dict = {}

  with open("metrics.yaml", 'r') as stream:
    try:
      metrics_dict = yaml.safe_load(stream)

      for metric_list in metrics_dict.values():
        for metric in metric_list.values():
          for sub_metric_key, sub_metric in metric.items():
            metric_link = f"custom.googleapis.com/{sub_metric['name']}"
            # If the metric doesn't exist yet, then we create it
            if metric_link not in existing_metrics:
              create_metric(sub_metric["name"], sub_metric["description"])
            # Parse limits (both default values and network specific ones)
            if sub_metric_key == "limit":
              limits_dict_for_metric = {}
              for network_link, limit_value in sub_metric["values"].items():
                limits_dict_for_metric[network_link] = limit_value
              limits_dict[sub_metric["name"]] = limits_dict_for_metric
            
      return metrics_dict, limits_dict
    except yaml.YAMLError as exc:
      print(exc)


def create_metric(metric_name, description):
  '''
    Creates a Cloud Monitoring metric based on the parameter given if the metric is not already existing

      Parameters:
        metric_name (string): Name of the metric to be created
        description (string): Description of the metric to be created

      Returns:
        None
  '''
  client = monitoring_v3.MetricServiceClient()

  descriptor = ga_metric.MetricDescriptor()
  descriptor.type = f"custom.googleapis.com/{metric_name}"
  descriptor.metric_kind = ga_metric.MetricDescriptor.MetricKind.GAUGE
  descriptor.value_type = ga_metric.MetricDescriptor.ValueType.DOUBLE
  descriptor.description = description
  descriptor = client.create_metric_descriptor(name=MONITORING_PROJECT_LINK,
                                               metric_descriptor=descriptor)
  print("Created {}.".format(descriptor.name))


def get_gce_instances_data(metrics_dict, gce_instance_dict, limit_dict):
  '''
    Gets the data for GCE instances per VPC Network and writes it to the metric defined in instance_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
        gce_instance_dict (dictionary of string: int): Keys are the network links and values are the number of GCE Instances per network.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        gce_instance_dict
  '''
  # Existing GCP Monitoring metrics for GCE instances
  metric_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

  for project in MONITORED_PROJECTS_LIST:
    network_dict = get_networks(project)

    current_quota_limit = get_quota_current_limit(f"projects/{project}",
                                                  metric_instances_limit)
    current_quota_limit_view = customize_quota_view(current_quota_limit)

    for net in network_dict:
      set_limits(net, current_quota_limit_view, limit_dict)

      network_link = f"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{net['network_name']}"

      usage = 0
      if network_link in gce_instance_dict:
        usage = gce_instance_dict[network_link]

      write_data_to_metric(
          project, usage, metrics_dict["metrics_per_network"]
          ["instance_per_network"]["usage"]["name"], net['network_name'])
      write_data_to_metric(
          project, net['limit'], metrics_dict["metrics_per_network"]
          ["instance_per_network"]["limit"]["name"], net['network_name'])
      write_data_to_metric(
          project, usage / net['limit'], metrics_dict["metrics_per_network"]
          ["instance_per_network"]["utilization"]["name"], net['network_name'])

    print(f"Wrote number of instances to metric for projects/{project}")


def get_vpc_peering_data(metrics_dict, limit_dict):
  '''
    Gets the data for VPC peerings (active or not) and writes it to the metric defined (vpc_peering_active_metric and vpc_peering_metric).

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        None
  '''
  for project in MONITORED_PROJECTS_LIST:
    active_vpc_peerings, vpc_peerings = gather_vpc_peerings_data(project, limit_dict)
    for peering in active_vpc_peerings:
      write_data_to_metric(
          project, peering['active_peerings'],
          metrics_dict["metrics_per_network"]["vpc_peering_active_per_network"]
          ["usage"]["name"], peering['network_name'])
      write_data_to_metric(
          project, peering['network_limit'], metrics_dict["metrics_per_network"]
          ["vpc_peering_active_per_network"]["limit"]["name"],
          peering['network_name'])
      write_data_to_metric(
          project, peering['active_peerings'] / peering['network_limit'],
          metrics_dict["metrics_per_network"]["vpc_peering_active_per_network"]
          ["utilization"]["name"], peering['network_name'])
    print("Wrote number of active VPC peerings to custom metric for project:",
          project)

    for peering in vpc_peerings:
      write_data_to_metric(
          project, peering['peerings'], metrics_dict["metrics_per_network"]
          ["vpc_peering_per_network"]["usage"]["name"], peering['network_name'])
      write_data_to_metric(
          project, peering['network_limit'], metrics_dict["metrics_per_network"]
          ["vpc_peering_per_network"]["limit"]["name"], peering['network_name'])
      write_data_to_metric(
          project, peering['peerings'] / peering['network_limit'],
          metrics_dict["metrics_per_network"]["vpc_peering_per_network"]
          ["utilization"]["name"], peering['network_name'])
    print("Wrote number of VPC peerings to custom metric for project:", project)


def gather_vpc_peerings_data(project_id, limit_dict):
  '''
    Gets the data for all VPC peerings (active or not) in project_id and writes it to the metric defined in vpc_peering_active_metric and vpc_peering_metric.

      Parameters:
        project_id (string): We will take all VPCs in that project_id and look for all peerings to these VPCs.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        active_peerings_dict (dictionary of string: string): Contains project_id, network_name, network_limit for each active VPC peering.
        peerings_dict (dictionary of string: string): Contains project_id, network_name, network_limit for each VPC peering.
  '''
  active_peerings_dict = []
  peerings_dict = []
  request = service.networks().list(project=project_id)
  response = request.execute()
  if 'items' in response:
    for network in response['items']:
      if 'peerings' in network:
        STATE = network['peerings'][0]['state']
        if STATE == "ACTIVE":
          active_peerings_count = len(network['peerings'])
        else:
          active_peerings_count = 0

        peerings_count = len(network['peerings'])
      else:
        peerings_count = 0
        active_peerings_count = 0
      
      network_link = f"https://www.googleapis.com/compute/v1/projects/{project_id}/global/networks/{network['name']}"
      network_limit = get_limit_ppg(network_link, limit_dict)

      active_d = {
          'project_id': project_id,
          'network_name': network['name'],
          'active_peerings': active_peerings_count,
          'network_limit': network_limit
      }
      active_peerings_dict.append(active_d)
      d = {
          'project_id': project_id,
          'network_name': network['name'],
          'peerings': peerings_count,
          'network_limit': network_limit
      }
      peerings_dict.append(d)

  return active_peerings_dict, peerings_dict


def get_limit_ppg(network_link, limit_dict):
  '''
    Checks if this network has a specific limit for a metric, if so, returns that limit, if not, returns the default limit.

      Parameters:
        network_link (string): VPC network link.
        limit_list (list of string): Used to get the limit per VPC or the default limit.
      Returns:
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
  '''
  if network_link in limit_dict:
    return limit_dict[network_link]
  else:
    if 'default_value' in limit_dict:
      return limit_dict['default_value']
    else:
      print(f"Error: limit not found for {network_link}")
      return 0


def get_l4_forwarding_rules_data(metrics_dict, forwarding_rules_dict, limit_dict):
  '''
    Gets the data for L4 Internal Forwarding Rules per VPC Network and writes it to the metric defined in forwarding_rules_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions.
        forwarding_rules_dict (dictionary of string: int): Keys are the network links and values are the number of Forwarding Rules per network.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value.
      Returns:
        None
  '''
  for project in MONITORED_PROJECTS_LIST:
    network_dict = get_networks(project)

    current_quota_limit = get_quota_current_limit(f"projects/{project}",
                                                  L4_FORWARDING_RULES_LIMIT_METRIC)

    current_quota_limit_view = customize_quota_view(current_quota_limit)

    for net in network_dict:
      set_limits(net, current_quota_limit_view, limit_dict)

      network_link = f"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{net['network_name']}"

      usage = 0
      if network_link in forwarding_rules_dict:
        usage = forwarding_rules_dict[network_link]

      write_data_to_metric(
          project, usage, metrics_dict["metrics_per_network"]
          ["l4_forwarding_rules_per_network"]["usage"]["name"],
          net['network_name'])
      write_data_to_metric(
          project, net['limit'], metrics_dict["metrics_per_network"]
          ["l4_forwarding_rules_per_network"]["limit"]["name"],
          net['network_name'])
      write_data_to_metric(
          project, usage / net['limit'], metrics_dict["metrics_per_network"]
          ["l4_forwarding_rules_per_network"]["utilization"]["name"],
          net['network_name'])

    print(
        f"Wrote number of L4 forwarding rules to metric for projects/{project}")


def get_pgg_data(metric_dict, usage_dict, limit_metric, limit_dict):
  '''
    This function gets the usage, limit and utilization per VPC peering group for a specific metric for all projects to be monitored.

      Parameters:
        metric_dict (dictionary of string: string): Dictionary with the metric names and description, that will be used to populate the metrics
        usage_metric (string): Name of the existing GCP metric for usage per VPC network.
        usage_dict (dictionnary of string:int): Dictionary with the network link as key and the number of resources as value
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        None
  '''
  for project in MONITORED_PROJECTS_LIST:
    network_dict_list = gather_peering_data(project)
    # Network dict list is a list of dictionary (one for each network)
    # For each network, this dictionary contains:
    #   project_id, network_name, network_id, usage, limit, peerings (list of peered networks)
    #   peerings is a list of dictionary (one for each peered network) and contains:
    #     project_id, network_name, network_id

    # For each network in this GCP project
    for network_dict in network_dict_list:
      network_link = f"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{network_dict['network_name']}"

      current_quota_limit = get_quota_current_limit(f"projects/{project}",
                                                    limit_metric)
      current_quota_limit_view = customize_quota_view(current_quota_limit)
      limit = get_limit_network(network_dict, network_link, current_quota_limit_view,
                               limit_dict)

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

        peering_project_limit = customize_quota_view(
            get_quota_current_limit(f"projects/{peered_network_dict['project_id']}",
                                    limit_metric))

        peered_limit = get_limit_network(peered_network_dict, peered_network_link, peering_project_limit,
                                        limit_dict)
        # Here we add usage and limit to the peered network dictionary
        peered_network_dict["usage"] = peered_usage
        peered_network_dict["limit"] = peered_limit

      count_effective_limit(project, network_dict, metric_dict["usage"]["name"],
                            metric_dict["limit"]["name"],
                            metric_dict["utilization"]["name"], limit_dict)
      print(
          f"Wrote {metric_dict['usage']['name']} to metric for peering group {network_dict['network_name']} in {project}"
      )


def count_effective_limit(project_id, network_dict, usage_metric_name,
                          limit_metric_name, utilization_metric_name,
                          limit_dict):
  '''
    Calculates the effective limits (using algorithm in the link below) for peering groups and writes data (usage, limit, utilization) to the custom metrics.
    Source: https://cloud.google.com/vpc/docs/quota#vpc-peering-effective-limit

      Parameters:
        project_id (string): Project ID for the project to be analyzed.
        network_dict (dictionary of string: string): Contains all required information about the network to get the usage, limit and utilization.
        usage_metric_name (string): Name of the custom metric to be populated for usage per VPC peering group.
        limit_metric_name (string): Name of the custom metric to be populated for limit per VPC peering group.
        utilization_metric_name (string): Name of the custom metric to be populated for utilization per VPC peering group.
        limit_dict (dictionary of string:int): Dictionary containing the limit per peering group (either VPC specific or default limit).
      Returns:
        None
  '''

  if network_dict['peerings'] == []:
    return

  # Get usage: Sums usage for current network + all peered networks
  peering_group_usage = network_dict['usage']
  for peered_network in network_dict['peerings']:
    peering_group_usage += peered_network['usage']

  network_link = f"https://www.googleapis.com/compute/v1/projects/{project_id}/global/networks/{network_dict['network_name']}"

  # Calculates effective limit: Step 1: max(per network limit, per network_peering_group limit)
  limit_step1 = max(network_dict['limit'], get_limit_ppg(network_link, limit_dict))

  # Calculates effective limit: Step 2: List of max(per network limit, per network_peering_group limit) for each peered network
  limit_step2 = []
  for peered_network in network_dict['peerings']:
    peered_network_link = f"https://www.googleapis.com/compute/v1/projects/{peered_network['project_id']}/global/networks/{peered_network['network_name']}"

    limit_step2.append(
        max(peered_network['limit'],
            get_limit_ppg(peered_network_link, limit_dict)))

  # Calculates effective limit: Step 3: Find minimum from the list created by Step 2
  limit_step3 = min(limit_step2)

  # Calculates effective limit: Step 4: Find maximum from step 1 and step 3
  effective_limit = max(limit_step1, limit_step3)
  utilization = peering_group_usage / effective_limit

  write_data_to_metric(project_id, peering_group_usage, usage_metric_name,
                       network_dict['network_name'])
  write_data_to_metric(project_id, effective_limit, limit_metric_name,
                       network_dict['network_name'])
  write_data_to_metric(project_id, utilization, utilization_metric_name,
                       network_dict['network_name'])

def get_networks(project_id):
  '''
    Returns a dictionary of all networks in a project.

      Parameters:
        project_id (string): Project ID for the project containing the networks.
      Returns:
        network_dict (dictionary of string: string): Contains the project_id, network_name(s) and network_id(s)
  '''
  request = service.networks().list(project=project_id)
  response = request.execute()
  network_dict = []
  if 'items' in response:
    for network in response['items']:
      network_name = network['name']
      network_id = network['id']
      d = {'project_id': project_id, 'network_name': network_name, 'network_id': network_id}
      network_dict.append(d)
  return network_dict

# TODO: list all routers (https://cloud.google.com/compute/docs/reference/rest/v1/routers/list) then https://cloud.google.com/compute/docs/reference/rest/v1/routers/getRouterStatus
def get_routes(project_id):
  '''
    Returns a dictionary of all dynamic routes in a project.

      Parameters:
        project_id (string): Project ID for the project containing the networks.
      Returns:
        network_dict (dictionary of string: string): Contains the project_id, network_name(s) and network_id(s)
  '''
  request = service.routers().list(project=project_id)
  response = request.execute()
  network_dict = []
  if 'items' in response:
    for router in response['items']:
      network_name = router['name']
      network_id = router['id']
      d = {'project_id': project_id, 'network name': network_name, 'network id': network_id}
      network_dict.append(d)
  return network_dict

def gather_peering_data(project_id):
  '''
    Returns a dictionary of all peerings for all networks in a project.

      Parameters:
        project_id (string): Project ID for the project containing the networks.
      Returns:
        network_list (dictionary of string: string): Contains the project_id, network_name(s) and network_id(s) of peered networks.
  '''
  request = service.networks().list(project=project_id)
  response = request.execute()

  network_list = []
  if 'items' in response:
    for network in response['items']:
      net = {
          'project_id': project_id,
          'network_name': network['name'],
          'network_id': network['id'],
          'peerings': []
      }
      if 'peerings' in network:
        STATE = network['peerings'][0]['state']
        if STATE == "ACTIVE":
          for peered_network in network[
              'peerings']:  # "projects/{project_name}/global/networks/{network_name}"
            start = peered_network['network'].find("projects/") + len(
                'projects/')
            end = peered_network['network'].find("/global")
            peered_project = peered_network['network'][start:end]
            peered_network_name = peered_network['network'].split(
                "networks/")[1]
            peered_net = {
                'project_id':
                    peered_project,
                'network_name':
                    peered_network_name,
                'network_id':
                    get_network_id(peered_project, peered_network_name)
            }
            net["peerings"].append(peered_net)
      network_list.append(net)
  return network_list


def get_network_id(project_id, network_name):
  '''
    Returns the network_id for a specific project / network name.

      Parameters:
        project_id (string): Project ID for the project containing the networks.
        network_name (string): Name of the network
      Returns:
        network_id (int): Network ID.
  '''
  request = service.networks().list(project=project_id)
  response = request.execute()

  network_id = 0

  if 'items' in response:
    for network in response['items']:
      if network['name'] == network_name:
        network_id = network['id']
        break

  if network_id == 0:
    print(f"Error: network_id not found for {network_name} in {project_id}")

  return network_id

def get_quota_current_limit(project_link, metric_name):
  '''
    Retrieves limit for a specific metric.

      Parameters:
        project_link (string): Project link.
        metric_name (string): Name of the metric.
      Returns:
        results_list (list of string): Current limit.
  '''
  client, interval = create_client()

  results = client.list_time_series(
      request={
          "name": project_link,
          "filter": f'metric.type = "{metric_name}"',
          "interval": interval,
          "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
      })
  results_list = list(results)
  return results_list


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


def set_limits(network_dict, quota_limit, limit_dict):
  '''
    Updates the network dictionary with quota limit values. 

      Parameters:
        network_dict (dictionary of string: string): Contains network information.
        quota_limit (list of dictionaries of string: string): Current quota limit.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        None
  '''

  network_dict['limit'] = None
  
  if quota_limit:
    for net in quota_limit:
      if net['network_id'] == network_dict[
          'network_id']:
        network_dict['limit'] = net['value']
        return

  network_link = f"https://www.googleapis.com/compute/v1/projects/{network_dict['project_id']}/global/networks/{network_dict['network_name']}"

  if network_link in limit_dict:
    network_dict['limit'] = limit_dict[network_link]
  else:
    if 'default_value' in limit_dict:
      network_dict['limit'] = limit_dict['default_value']
    else:
      print(f"Error: Couldn't find limit for {network_link}")
      network_dict['limit'] = 0

def get_limit_network(network_dict, network_link, quota_limit, limit_dict):
  '''
    Returns limit for a specific network and metric, using the GCP quota metrics or the values in the yaml file if not found.

      Parameters:
        network_dict (dictionary of string: string): Contains network information.
        network_link (string): Contains network link
        quota_limit (list of dictionaries of string: string): Current quota limit for all networks in that project.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        limit (int): Current limit for that network.
  '''
  if quota_limit:
    for net in quota_limit:
      if net['network_id'] == network_dict['network_id']:  
        return net['value']
  
  if network_link in limit_dict:
    return limit_dict[network_link]
  else:
    if 'default_value' in limit_dict:
      return limit_dict['default_value']
    else:
      print(f"Error: Couldn't find limit for {network_link}")

  return 0


def write_data_to_metric(monitored_project_id, value, metric_name,
                         network_name):
  '''
    Writes data to Cloud Monitoring custom metrics.

      Parameters:
        monitored_project_id: ID of the project where the resource lives (will be added as a label)
        value (int): Value for the data point of the metric.
        metric_name (string): Name of the metric
        network_name (string): Name of the network (will be added as a label)
      Returns:
        usage (int): Current usage for that network.
        limit (int): Current usage for that network.
  '''
  client = monitoring_v3.MetricServiceClient()

  series = monitoring_v3.TimeSeries()
  series.metric.type = f"custom.googleapis.com/{metric_name}"
  series.resource.type = "global"
  series.metric.labels["network_name"] = network_name
  series.metric.labels["project"] = monitored_project_id

  now = time.time()
  seconds = int(now)
  nanos = int((now - seconds) * 10**9)
  interval = monitoring_v3.TimeInterval(
      {"end_time": {
          "seconds": seconds,
          "nanos": nanos
      }})
  point = monitoring_v3.Point({
      "interval": interval,
      "value": {
          "double_value": value
      }
  })
  series.points = [point]

  # TODO: sometimes this cashes with 'DeadlineExceeded: 504 Deadline expired before operation could complete' error
  # Implement exponential backoff retries?
  try:
    client.create_time_series(name=MONITORING_PROJECT_LINK, time_series=[series])
  except Exception as e:
    print(e)