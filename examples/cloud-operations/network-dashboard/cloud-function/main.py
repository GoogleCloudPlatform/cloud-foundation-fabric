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

from google.cloud import monitoring_v3
from googleapiclient import discovery
from google.api import metric_pb2 as ga_metric
import time
import os
import google.api_core
import re
import random
import yaml

monitored_projects_list = os.environ.get("monitored_projects_list").split(",")  # list of projects from which function will get quotas information
monitoring_project_id = os.environ.get("monitoring_project_id")  # project where the metrics and dahsboards will be created
monitoring_project_link = f"projects/{monitoring_project_id}"
service = discovery.build('compute', 'v1')

# DEFAULT LIMITS:
limit_vpc_peer = os.environ.get("LIMIT_VPC_PEER").split(",")
limit_l4 = os.environ.get("LIMIT_L4").split(",")
limit_l7 = os.environ.get("LIMIT_L7").split(",")
limit_instances = os.environ.get("LIMIT_INSTANCES").split(",")
limit_instances_ppg = os.environ.get("LIMIT_INSTANCES_PPG").split(",")
limit_subnets = os.environ.get("LIMIT_SUBNETS").split(",")
limit_l4_ppg = os.environ.get("LIMIT_L4_PPG").split(",")
limit_l7_ppg = os.environ.get("LIMIT_L7_PPG").split(",")

def main(event, context):
  '''
    Cloud Function Entry point, called by the scheduler.

      Parameters:
        event: Not used for now (Pubsub trigger)
        context: Not used for now (Pubsub trigger)
      Returns:
        'Function executed successfully'
  '''
  global client, interval
  client, interval = create_client()

  metrics_dict = create_metrics()

  # Per Network metrics
  get_gce_instances_data(metrics_dict)
  get_vpc_peering_data(metrics_dict)
  get_l4_forwarding_rules_data(metrics_dict)

  # Existing GCP Monitoring metrics for L4 Forwarding Rules per Network
  l4_forwarding_rules_usage = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/usage"
  l4_forwarding_rules_limit = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit"

  get_pgg_data(metrics_dict["metrics_per_peering_group"]["l4_forwarding_rules_per_peering_group"], l4_forwarding_rules_usage, l4_forwarding_rules_limit, limit_l4_ppg)

  # Existing GCP Monitoring metrics for L7 Forwarding Rules per Network
  l7_forwarding_rules_usage = "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/usage"
  l7_forwarding_rules_limit = "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/limit"

  get_pgg_data(metrics_dict["metrics_per_peering_group"]["l7_forwarding_rules_per_peering_group"], l7_forwarding_rules_usage, l7_forwarding_rules_limit, limit_l7_ppg)

  # Existing GCP Monitoring metrics for Subnet Ranges per Network
  subnet_ranges_usage = "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/usage"
  subnet_ranges_limit = "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/limit"

  get_pgg_data(metrics_dict["metrics_per_peering_group"]["subnet_ranges_per_peering_group"], subnet_ranges_usage, subnet_ranges_limit, limit_subnets)

  # Existing GCP Monitoring metrics for GCE per Network
  gce_instances_usage = "compute.googleapis.com/quota/instances_per_vpc_network/usage"
  gce_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

  get_pgg_data(metrics_dict["metrics_per_peering_group"]["instance_per_peering_group"], gce_instances_usage, gce_instances_limit, limit_instances_ppg)

  return 'Function executed successfully'

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
    nanos = int((now - seconds) * 10 ** 9)
    interval = monitoring_v3.TimeInterval(
    {
      "end_time": {"seconds": seconds, "nanos": nanos},
      "start_time": {"seconds": (seconds - 86400), "nanos": nanos},
    })
    return (client, interval)
  except Exception as e:
    raise Exception("Error occurred creating the client: {}".format(e))

def create_metrics():
  with open("metrics.yaml", 'r') as stream:
    try:
        metrics_dict = yaml.safe_load(stream)

        for metric_list in metrics_dict.values():
          for metric in metric_list.values():
            for sub_metric in metric.values():
              create_metric(sub_metric["name"], sub_metric["description"])

        return metrics_dict
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

  metric_link = f"custom.googleapis.com/{metric_name}"
  types = []
  for desc in client.list_metric_descriptors(name=monitoring_project_link):
    types.append(desc.type)

  if metric_link not in types: # If the metric doesn't exist yet, then we create it
    descriptor = ga_metric.MetricDescriptor()
    descriptor.type = f"custom.googleapis.com/{metric_name}"
    descriptor.metric_kind = ga_metric.MetricDescriptor.MetricKind.GAUGE
    descriptor.value_type = ga_metric.MetricDescriptor.ValueType.DOUBLE
    descriptor.description = description
    descriptor = client.create_metric_descriptor(name=monitoring_project_link, metric_descriptor=descriptor)
    print("Created {}.".format(descriptor.name))

def get_gce_instances_data(metrics_dict):
  '''
    Gets the data for GCE instances per VPC Network and writes it to the metric defined in instance_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
      Returns:
        None
  '''
  # Existing GCP Monitoring metrics for GCE instances
  metric_instances_usage = "compute.googleapis.com/quota/instances_per_vpc_network/usage"
  metric_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

  for project in monitored_projects_list:
    network_dict = get_networks(project)

    current_quota_usage = get_quota_current_usage(f"projects/{project}", metric_instances_usage)
    current_quota_limit = get_quota_current_limit(f"projects/{project}", metric_instances_limit)

    current_quota_usage_view = customize_quota_view(current_quota_usage)
    current_quota_limit_view = customize_quota_view(current_quota_limit)

    for net in network_dict:
      set_usage_limits(net, current_quota_usage_view, current_quota_limit_view, limit_instances)
      write_data_to_metric(project, net['usage'], metrics_dict["metrics_per_network"]["instance_per_network"]["usage"]["name"], net['network name'])
      write_data_to_metric(project, net['limit'], metrics_dict["metrics_per_network"]["instance_per_network"]["limit"]["name"], net['network name'])
      write_data_to_metric(project, net['usage']/ net['limit'], metrics_dict["metrics_per_network"]["instance_per_network"]["utilization"]["name"], net['network name'])

    print(f"Wrote number of instances to metric for projects/{project}")


def get_vpc_peering_data(metrics_dict):
  '''
    Gets the data for VPC peerings (active or not) and writes it to the metric defined (vpc_peering_active_metric and vpc_peering_metric).

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
      Returns:
        None
  '''
  for project in monitored_projects_list:
    active_vpc_peerings, vpc_peerings = gather_vpc_peerings_data(project, limit_vpc_peer) 
    for peering in active_vpc_peerings:
      write_data_to_metric(project, peering['active_peerings'], metrics_dict["metrics_per_network"]["vpc_peering_active_per_network"]["usage"]["name"], peering['network_name'])
      write_data_to_metric(project, peering['network_limit'], metrics_dict["metrics_per_network"]["vpc_peering_active_per_network"]["limit"]["name"], peering['network_name'])
      write_data_to_metric(project, peering['active_peerings'] / peering['network_limit'], metrics_dict["metrics_per_network"]["vpc_peering_active_per_network"]["utilization"]["name"], peering['network_name'])
    print("Wrote number of active VPC peerings to custom metric for project:", project)

    for peering in vpc_peerings:
      write_data_to_metric(project, peering['peerings'], metrics_dict["metrics_per_network"]["vpc_peering_per_network"]["usage"]["name"], peering['network_name'])
      write_data_to_metric(project, peering['network_limit'], metrics_dict["metrics_per_network"]["vpc_peering_per_network"]["limit"]["name"], peering['network_name'])
      write_data_to_metric(project, peering['peerings'] / peering['network_limit'], metrics_dict["metrics_per_network"]["vpc_peering_per_network"]["utilization"]["name"], peering['network_name'])
    print("Wrote number of VPC peerings to custom metric for project:", project)

def gather_vpc_peerings_data(project_id, limit_list):
  '''
    Gets the data for all VPC peerings (active or not) in project_id and writes it to the metric defined in vpc_peering_active_metric and vpc_peering_metric.

      Parameters:
        project_id (string): We will take all VPCs in that project_id and look for all peerings to these VPCs.
        limit_list (list of string): Used to get the limit per VPC or the default limit.
      Returns:
        active_peerings_dict (dictionary of string: string): Contains project_id, network_name, network_limit for each active VPC peering.
        peerings_dict (dictionary of string: string): Contains project_id, network_name, network_limit for each VPC peering.
  '''
  active_peerings_dict  = []
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

      active_d = {'project_id': project_id,'network_name':network['name'],'active_peerings':active_peerings_count,'network_limit': get_limit(network['name'], limit_list)}
      active_peerings_dict.append(active_d)
      d = {'project_id': project_id,'network_name':network['name'],'peerings':peerings_count,'network_limit': get_limit(network['name'], limit_list)}
      peerings_dict.append(d)

  return active_peerings_dict, peerings_dict

def get_limit(network_name, limit_list):
  '''
    Checks if this network has a specific limit for a metric, if so, returns that limit, if not, returns the default limit.

      Parameters:
        network_name (string): Name of the VPC network.
        limit_list (list of string): Used to get the limit per VPC or the default limit.
      Returns:
        limit (int): Limit for that VPC and that metric.
  '''
  if network_name in limit_list:
    return int(limit_list[limit_list.index(network_name) + 1])
  else:
    if 'default_value' in limit_list:
      return int(limit_list[limit_list.index('default_value') + 1])
    else:
      return 0

def get_l4_forwarding_rules_data(metrics_dict):
  '''
    Gets the data for L4 Internal Forwarding Rules per VPC Network and writes it to the metric defined in forwarding_rules_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
      Returns:
        None
  '''
  # Existing GCP Monitoring metrics for L4 Forwarding Rules
  l4_forwarding_rules_usage = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/usage"
  l4_forwarding_rules_limit = "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit"

  for project in monitored_projects_list:
    network_dict = get_networks(project)

    current_quota_usage = get_quota_current_usage(f"projects/{project}", l4_forwarding_rules_usage)
    current_quota_limit = get_quota_current_limit(f"projects/{project}", l4_forwarding_rules_limit)

    current_quota_usage_view = customize_quota_view(current_quota_usage)
    current_quota_limit_view = customize_quota_view(current_quota_limit)

    for net in network_dict:
      set_usage_limits(net, current_quota_usage_view, current_quota_limit_view, limit_l4)
      write_data_to_metric(project, net['usage'], metrics_dict["metrics_per_network"]["l4_forwarding_rules_per_network"]["usage"]["name"], net['network name'])
      write_data_to_metric(project, net['limit'], metrics_dict["metrics_per_network"]["l4_forwarding_rules_per_network"]["limit"]["name"], net['network name'])
      write_data_to_metric(project, net['usage']/ net['limit'], metrics_dict["metrics_per_network"]["l4_forwarding_rules_per_network"]["utilization"]["name"], net['network name'])

    print(f"Wrote number of L4 forwarding rules to metric for projects/{project}")

def get_pgg_data(metric_dict, usage_metric, limit_metric, limit_ppg):
  '''
    This function gets the usage, limit and utilization per VPC peering group for a specific metric for all projects to be monitored.

      Parameters:
        metric_dict (dictionary of string: string): A dictionary with the metric names and description, that will be used later on to create the metrics in create_metric(metric_name, description)
        usage_metric (string): Name of the existing GCP metric for usage per VPC network.
        limit_metric (string): Name of the existing GCP metric for limit per VPC network.
        limit_ppg (list of string): List containing the limit per peering group (either VPC specific or default limit).
      Returns:
        None
  '''
  for project in monitored_projects_list:
    network_dict_list = gather_peering_data(project)
    # Network dict list is a list of dictionary (one for each network)
    # For each network, this dictionary contains:
    #   project_id, network_name, network_id, usage, limit, peerings (list of peered networks)
    #   peerings is a list of dictionary (one for each peered network) and contains:
    #     project_id, network_name, network_id
    
    # For each network in this GCP project
    for network_dict in network_dict_list:
      current_quota_usage = get_quota_current_usage(f"projects/{project}", usage_metric)
      current_quota_limit = get_quota_current_limit(f"projects/{project}", limit_metric)

      current_quota_usage_view = customize_quota_view(current_quota_usage)
      current_quota_limit_view = customize_quota_view(current_quota_limit)

      usage, limit = get_usage_limit(network_dict, current_quota_usage_view, current_quota_limit_view, limit_ppg)
      # Here we add usage and limit to the network dictionary
      network_dict["usage"] = usage
      network_dict["limit"] = limit

      # For every peered network, get usage and limits
      for peered_network in network_dict['peerings']:
        peering_project_usage = customize_quota_view(get_quota_current_usage(f"projects/{peered_network['project_id']}", usage_metric))
        peering_project_limit = customize_quota_view(get_quota_current_limit(f"projects/{peered_network['project_id']}", limit_metric))

        usage, limit = get_usage_limit(peered_network, peering_project_usage, peering_project_limit, limit_ppg)
        # Here we add usage and limit to the peered network dictionary
        peered_network["usage"] = usage
        peered_network["limit"] = limit

      count_effective_limit(project, network_dict, metric_dict["usage"]["name"], metric_dict["limit"]["name"], metric_dict["utilization"]["name"], limit_ppg)
      print(f"Wrote {metric_dict['usage']['name']} to metric for peering group {network_dict['network_name']} in {project}")

def count_effective_limit(project_id, network_dict, usage_metric_name, limit_metric_name, utilization_metric_name, limit_ppg):
  '''
    Calculates the effective limits (using algorithm in the link below) for peering groups and writes data (usage, limit, utilization) to the custom metrics.
    Source: https://cloud.google.com/vpc/docs/quota#vpc-peering-effective-limit

      Parameters:
        project_id (string): Project ID for the project to be analyzed.
        network_dict (dictionary of string: string): Contains all required information about the network to get the usage, limit and utilization.
        usage_metric_name (string): Name of the custom metric to be populated for usage per VPC peering group.
        limit_metric_name (string): Name of the custom metric to be populated for limit per VPC peering group.
        utilization_metric_name (string): Name of the custom metric to be populated for utilization per VPC peering group.
        limit_ppg (list of string): List containing the limit per peering group (either VPC specific or default limit).
      Returns:
        None
  '''

  if network_dict['peerings'] == []:
    return

  # Get usage: Sums usage for current network + all peered networks
  peering_group_usage = network_dict['usage']
  for peered_network in network_dict['peerings']:
    peering_group_usage += peered_network['usage']

  # Calculates effective limit: Step 1: max(per network limit, per network_peering_group limit)
  limit_step1 = max(network_dict['limit'], get_limit(network_dict['network_name'], limit_ppg))

  # Calculates effective limit: Step 2: List of max(per network limit, per network_peering_group limit) for each peered network
  limit_step2 = []
  for peered_network in network_dict['peerings']:
    limit_step2.append(max(peered_network['limit'], get_limit(peered_network['network_name'], limit_ppg)))

  # Calculates effective limit: Step 3: Find minimum from the list created by Step 2
  limit_step3 = min(limit_step2)

  # Calculates effective limit: Step 4: Find maximum from step 1 and step 3
  effective_limit = max(limit_step1, limit_step3)
  utilization = peering_group_usage / effective_limit

  write_data_to_metric(project_id, peering_group_usage, usage_metric_name, network_dict['network_name'])
  write_data_to_metric(project_id, effective_limit, limit_metric_name, network_dict['network_name'])
  write_data_to_metric(project_id, utilization, utilization_metric_name, network_dict['network_name'])

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
      NETWORK = network['name']
      ID = network['id']
      d = {'project_id':project_id,'network name':NETWORK,'network id':ID}
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
      net = {'project_id':project_id,'network_name':network['name'],'network_id':network['id'], 'peerings':[]}
      if 'peerings' in network:
        STATE = network['peerings'][0]['state']
        if STATE == "ACTIVE":
          for peered_network in network['peerings']:  # "projects/{project_name}/global/networks/{network_name}"
            start = peered_network['network'].find("projects/") + len('projects/')
            end = peered_network['network'].find("/global")
            peered_project = peered_network['network'][start:end]
            peered_network_name  = peered_network['network'].split("networks/")[1]
            peered_net = {'project_id': peered_project, 'network_name':peered_network_name, 'network_id': get_network_id(peered_project, peered_network_name)}
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

def get_quota_current_usage(project_link, metric_name):
  '''
    Retrieves quota usage for a specific metric.

      Parameters:
        project_link (string): Project link.
        metric_name (string): Name of the metric.
      Returns:
        results_list (list of string): Current usage.
  '''
  results = client.list_time_series(request={
    "name": project_link,
    "filter": f'metric.type = "{metric_name}"',
    "interval": interval,
    "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
  })
  results_list = list(results)
  return (results_list)

def get_quota_current_limit(project_link, metric_name):
  '''
    Retrieves limit for a specific metric.

      Parameters:
        project_link (string): Project link.
        metric_name (string): Name of the metric.
      Returns:
        results_list (list of string): Current limit.
  '''
  results = client.list_time_series(request={
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

def set_usage_limits(network_dict, quota_usage, quota_limit, limit_list):
  '''
    Updates the network dictionary with quota usage and limit values. 

      Parameters:
        network_dict (dictionary of string: string): Contains network information.
        quota_usage (list of dictionaries of string: string): Current quota usage.
        quota_limit (list of dictionaries of string: string): Current quota limit.
        limit_list (list of string): List containing the limit per VPC (either VPC specific or default limit).
      Returns:
        None
  '''
  if quota_usage:
    for net in quota_usage: 
      if net['network_id'] == network_dict['network id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
        network_dict['usage'] = net['value']  # set network usage in dictionary 
        break
      else:
        network_dict['usage'] = 0  # if network does not appear in GCP quotas
  else:
    network_dict['usage'] = 0  # if quotas does not appear in GCP quotas

  if quota_limit:
    for net in quota_limit:
      if net['network_id'] == network_dict['network id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
        network_dict['limit'] = net['value']  # set network limit in dictionary 
        break
      else:
        if network_dict['network name'] in limit_list:  # if network limit is in the environmental variables
          network_dict['limit'] = int(limit_list[limit_list.index(network_dict['network name']) + 1]) 
        else:
          network_dict['limit'] = int(limit_list[limit_list.index('default_value') + 1])  # set default value
  else:  # if quotas does not appear in GCP quotas
    if network_dict['network name'] in limit_list:
      network_dict['limit'] = int(limit_list[limit_list.index(network_dict['network name']) + 1])  # ["default", 100, "networkname", 200]
    else:
      network_dict['limit'] =  int(limit_list[limit_list.index('default_value') + 1])

def get_usage_limit(network, quota_usage, quota_limit, limit_list):
  '''
    Returns usage and limit for a specific network and metric.

      Parameters:
        network_dict (dictionary of string: string): Contains network information.
        quota_usage (list of dictionaries of string: string): Current quota usage for all networks in that project.
        quota_limit (list of dictionaries of string: string): Current quota limit for all networks in that project.
        limit_list (list of string): List containing the limit per VPC (either VPC specific or default limit).
      Returns:
        usage (int): Current usage for that network.
        limit (int): Current usage for that network.
  '''
  usage = 0
  limit = 0

  if quota_usage:
    for net in quota_usage: 
      if net['network_id'] == network['network_id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
        usage = net['value']  # set network usage in dictionary 
        break

  if quota_limit:
    for net in quota_limit:
      if net['network_id'] == network['network_id']:  # if network ids in GCP quotas and in dictionary (using API) are the same
        limit = net['value']  # set network limit in dictionary 
        break
      else:
        if network['network_name'] in limit_list:  # if network limit is in the environmental variables
          limit = int(limit_list[limit_list.index(network['network_name']) + 1]) 
        else:
          limit = int(limit_list[limit_list.index('default_value') + 1])  # set default value
  else:  # if quotas does not appear in GCP quotas
    if network['network_name'] in limit_list:
      limit = int(limit_list[limit_list.index(network['network_name']) + 1])  # ["default", 100, "networkname", 200]
    else:
      limit =  int(limit_list[limit_list.index('default_value') + 1])

  return usage, limit

def write_data_to_metric(monitored_project_id, value, metric_name, network_name):
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
  series = monitoring_v3.TimeSeries()
  series.metric.type = f"custom.googleapis.com/{metric_name}"
  series.resource.type = "global" 
  series.metric.labels["network_name"] = network_name
  series.metric.labels["project"] = monitored_project_id

  now = time.time()
  seconds = int(now)
  nanos = int((now - seconds) * 10 ** 9)
  interval = monitoring_v3.TimeInterval({"end_time": {"seconds": seconds, "nanos": nanos}})
  point = monitoring_v3.Point({"interval": interval, "value": {"double_value": value}})
  series.points = [point]

  client.create_time_series(name=monitoring_project_link, time_series=[series])