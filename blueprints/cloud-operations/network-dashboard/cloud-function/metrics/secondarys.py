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

from . import metrics
from google.protobuf import field_mask_pb2
from google.protobuf.json_format import MessageToDict
import ipaddress


def get_all_secondaryRange(config):
  '''
        Returns a dictionary with secondary range informations
            Parameters:
                config (dict): The dict containing config like clients and limits
            Returns:
                secondary_dict (dictionary of String: dictionary): Key is the project_id,
                value is a nested dictionary with subnet_name/secondary_range_name as the key.
    '''
  secondary_dict = {}
  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  response = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ['compute.googleapis.com/Subnetwork'],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response:
    for versioned in asset.versioned_resources:
      subnet_name = versioned.resource.get('name')
      # Network self link format:
      # "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/global/networks/<NETWORK_NAME>"
      project_id = versioned.resource.get('network').split('/')[6]
      network_name = versioned.resource.get('network').split('/')[-1]
      subnet_region = versioned.resource.get('region').split('/')[-1]

      # Check first if the subnet has any secondary ranges to begin with
      if versioned.resource.get('secondaryIpRanges'):
              for items in versioned.resource.get('secondaryIpRanges'):
                  # Each subnet can have multiple secondary ranges
                  secondaryRange_name = items.get('rangeName')
                  secondaryCidrBlock = items.get('ipCidrRange')

                  net = ipaddress.ip_network(secondaryCidrBlock)
                  total_ip_addresses = int(net.num_addresses)

                  if project_id not in secondary_dict:
                      secondary_dict[project_id] = {}
                  secondary_dict[project_id][f"{subnet_name}/{secondaryRange_name}"] = {
                      'name': secondaryRange_name,
                      'region': subnet_region,
                      'subnetName': subnet_name,
                      'ip_cidr_range': secondaryCidrBlock,
                      'total_ip_addresses': total_ip_addresses,
                      'used_ip_addresses': 0,
                      'network_name': network_name
                  }
  return secondary_dict


def compute_GKE_secondaryIP_utilization(config, read_mask, all_secondary_dict):
  '''
        Counts the IP Addresses used by GKE (Pods and Services)
            Parameters:
                config (dict): The dict containing config like clients and limits
                read_mask (FieldMask): read_mask to get additional metadata from Cloud Asset Inventory
                all_secondary_dict (dict): Dict containing the secondary IP Range information for each subnets in the GCP organization
            Returns:
                all_secondary_dict (dict): Same dict but populated with GKE IP utilization information
    '''
  cluster_secondary_dict = {}
  node_secondary_dict = {}

  # Creating cluster dict
  # Cluster dict has subnet information
  response_cluster = config["clients"]["asset_client"].list_assets(
      request={
          "parent": f"organizations/{config['organization']}",
          "asset_types": ['container.googleapis.com/Cluster'],
          "content_type": 'RESOURCE',
          "page_size": config["page_size"],
      })

  for asset in response_cluster:
    cluster_project = asset.resource.data['selfLink'].split('/')[5]
    cluster_parent = "/".join(asset.resource.data['selfLink'].split('/')[5:10])
    cluster_subnetwork = asset.resource.data['subnetwork']
    cluster_service_rangeName = asset.resource.data['ipAllocationPolicy'][
        'servicesSecondaryRangeName']

    cluster_secondary_dict[f"{cluster_parent}/Service"] = {
        "project": cluster_project,
        "subnet": cluster_subnetwork,
        "secondaryRange_name": cluster_service_rangeName,
        'used_ip_addresses': 0,
    }

    for node_pool in asset.resource.data['nodePools']:
      nodepool_name = node_pool['name']
      node_IPrange = node_pool['networkConfig']['podRange']
      cluster_secondary_dict[f"{cluster_parent}/{nodepool_name}"] = {
          "project": cluster_project,
          "subnet": cluster_subnetwork,
          "secondaryRange_name": node_IPrange,
          'used_ip_addresses': 0,
      }

  # Creating node dict
  # Node dict allows 1:1 mapping of pod IP utilization, and which secondary Range it is using
  response_node = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ['k8s.io/Node'],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response_node:
    # Node name link format:
    # "//container.googleapis.com/projects/<PROJECT_ID>/<zones/region>/<LOCATION>/clusters/<CLUSTER_NAME>/k8s/nodes/<NODE_NAME>"
    node_parent = "/".join(asset.name.split('/')[4:9])
    node_name = asset.name.split('/')[-1]
    node_full_name = f"{node_parent}/{node_name}"

    for versioned in asset.versioned_resources:
      node_secondary_dict[node_full_name] = {
          'node_parent':
              node_parent,
          'this_node_pool':
              versioned.resource['metadata']['labels']
              ['cloud.google.com/gke-nodepool'],
          'used_ip_addresses':
              0
      }

  # Counting IP addresses used by pods in GKE
  response_pods = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ['k8s.io/Pod'],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response_pods:
    # Pod name link format:
    # "//container.googleapis.com/projects/<PROJECT_ID>/<zones/region>/<LOCATION>/clusters/<CLUSTER_NAME>/k8s/namespaces/<NAMESPACE>/pods/<POD_NAME>"
    pod_parent = "/".join(asset.name.split('/')[4:9])

    for versioned in asset.versioned_resources:
      cur_PodIP = versioned.resource['status']['podIP']
      cur_HostIP = versioned.resource['status']['hostIP']
      host_node_name = versioned.resource['spec']['nodeName']
      pod_full_path = f"{pod_parent}/{host_node_name}"

      # A check to make sure pod is not using node IP
      if cur_PodIP != cur_HostIP:
        node_secondary_dict[pod_full_path]['used_ip_addresses'] += 1

  # Counting IP addresses used by Service in GKE
  response_service = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ['k8s.io/Service'],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response_service:
    service_parent = "/".join(asset.name.split('/')[4:9])
    service_fullpath = f"{service_parent}/Service"
    cluster_secondary_dict[service_fullpath]['used_ip_addresses'] += 1

  for item in node_secondary_dict.values():
    itemKey = f"{item['node_parent']}/{item['this_node_pool']}"
    cluster_secondary_dict[itemKey]['used_ip_addresses'] += item['used_ip_addresses']

  for item in cluster_secondary_dict.values():
    itemKey = f"{item['subnet']}/{item['secondaryRange_name']}"
    all_secondary_dict[item['project']][itemKey]['used_ip_addresses'] += item[
        'used_ip_addresses']


def compute_secondary_utilization(config, all_secondary_dict):
  '''
    Counts resources (GKE, GCE) using IPs in secondary ranges.
      Parameters:
        config (dict): Dict containing config like clients and limits
        all_secondary_dict (dict): Dict containing the secondary IP Range information for each subnets in the GCP organization
      Returns:
        None
  '''
  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  compute_GKE_secondaryIP_utilization(config, read_mask, all_secondary_dict)
  # TODO: Other Secondary IP like GCE VM using alias IPs


def get_secondaries(config, metrics_dict):
  '''
    Writes all secondary rang IP address usage metrics to custom metrics.
      Parameters:
        config (dict): The dict containing config like clients and limits
      Returns:
        None
  '''

  secondaryRange_dict = get_all_secondaryRange(config)
  # Updates all_subnets_dict with the IP utilization info
  compute_secondary_utilization(config, secondaryRange_dict)

  timestamp = time.time()
  for project_id in config["monitored_projects"]:
    if project_id not in secondaryRange_dict:
      continue
    for secondary_dict in secondaryRange_dict[project_id].values():
      ip_utilization = 0
      if secondary_dict['used_ip_addresses'] > 0:
        ip_utilization = secondary_dict['used_ip_addresses'] / secondary_dict[
            'total_ip_addresses']

      # Building unique identifier with subnet region/name
      subnet_id = f"{secondary_dict['region']}/{secondary_dict['name']}"
      metric_labels = {
          'project': project_id,
          'network_name': secondary_dict['network_name'],
          'region' : secondary_dict['region'],
          'subnet' : secondary_dict['subnetName'],
          'secondary_range' : secondary_dict['name']
      }
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]
          ["ip_usage_per_secondaryRange"]["usage"]["name"],
          secondary_dict['used_ip_addresses'], metric_labels,
          timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]
          ["ip_usage_per_secondaryRange"]["limit"]["name"],
          secondary_dict['total_ip_addresses'], metric_labels,
          timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]
          ["ip_usage_per_secondaryRange"]["utilization"]["name"],
          ip_utilization, metric_labels, timestamp=timestamp)

    print("Buffered metrics for secondary ip utilization for VPCs in project",
          project_id)
