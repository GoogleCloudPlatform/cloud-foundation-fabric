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

import time

from collections import defaultdict
from . import metrics, networks, limits, peerings, routers


def get_routes_for_router(config, project_id, router_region, router_name):
  '''
    Returns the same of dynamic routes learned by a specific Cloud Router instance

      Parameters:
        config (dict): The dict containing config like clients and limits
        project_id (string): Project ID for the project containing the Cloud Router.
        router_region (string): GCP region for the Cloud Router.
        router_name (string): Cloud Router name.
      Returns:
        sum_routes (int): Number of dynamic routes learned by the Cloud Router.
  '''
  request = config["clients"]["discovery_client"].routers().getRouterStatus(
      project=project_id, region=router_region, router=router_name)
  response = request.execute()

  sum_routes = 0

  if 'result' in response:
    if 'bgpPeerStatus' in response['result']:
      for peer in response['result']['bgpPeerStatus']:
        sum_routes += peer['numLearnedRoutes']

  return sum_routes


def get_routes_for_network(config, network_link, project_id, routers_dict):
  '''
    Returns a the number of dynamic routes for a given network

      Parameters:
        config (dict): The dict containing config like clients and limits
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
      routes = get_routes_for_router(config, project_id, router_region,
                                     router_name)

      sum_routes += routes

  return sum_routes


def get_dynamic_routes(config, metrics_dict, limits_dict):
  '''
    Writes all dynamic routes per VPC to custom metrics.

      Parameters:
        config (dict): The dict containing config like clients and limits
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions.
        limits_dict (dictionary of string: int): key is network link (or 'default_value') and value is the limit for that network
      Returns:
        dynamic_routes_dict (dictionary of string: int): key is network link and value is the number of dynamic routes for that network
  '''
  routers_dict = routers.get_routers(config)
  dynamic_routes_dict = defaultdict(int)

  timestamp = time.time()
  for project in config["monitored_projects"]:
    network_dict = networks.get_networks(config, project)

    for net in network_dict:
      sum_routes = get_routes_for_network(config, net['self_link'], project,
                                          routers_dict)
      dynamic_routes_dict[net['self_link']] = sum_routes

      if net['self_link'] in limits_dict:
        limit = limits_dict[net['self_link']]
      else:
        if 'default_value' in limits_dict:
          limit = limits_dict['default_value']
        else:
          print("Error: couldn't find limit for dynamic routes.")
          break

      utilization = sum_routes / limit
      metric_labels = {'project': project, 'network_name': net['network_name']}
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["usage"]["name"], sum_routes,
          metric_labels, timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["limit"]["name"], limit, metric_labels,
          timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_network"]
          ["dynamic_routes_per_network"]["utilization"]["name"], utilization,
          metric_labels, timestamp=timestamp)

    print("Buffered metrics for dynamic routes for VPCs in project", project)

    return dynamic_routes_dict


def get_dynamic_routes_ppg(config, metric_dict, usage_dict, limit_dict):
  '''
    This function gets the usage, limit and utilization for the dynamic routes per VPC peering group.

      Parameters:
        config (dict): The dict containing config like clients and limits
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

      limits.count_effective_limit(config, project, network_dict,
                                   metric_dict["usage"]["name"],
                                   metric_dict["limit"]["name"],
                                   metric_dict["utilization"]["name"],
                                   limit_dict)
      print(
          f"Wrote {metric_dict['usage']['name']} for peering group {network_dict['network_name']} in {project}"
      )
