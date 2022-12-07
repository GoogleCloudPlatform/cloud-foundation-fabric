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


def get_all_subnets(config):
  '''
    Returns a dictionary with subnet level informations (such as IP utilization)
      Parameters:
        config (dict): The dict containing config like clients and limits
      Returns:
        subnet_dict (dictionary of String: dictionary): Key is the project_id, value is a nested dictionary with subnet_region/subnet_name as the key.
  '''
  subnet_dict = {}
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
      subnet_name = ""
      network_name = ""
      project_id = ""
      ip_cidr_range = ""
      subnet_region = ""

      for field_name, field_value in versioned.resource.items():
        if field_name == 'name':
          subnet_name = field_value
        elif field_name == 'network':
          # Network self link format:
          # "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/global/networks/<NETWORK_NAME>"
          project_id = field_value.split('/')[6]
          network_name = field_value.split('/')[-1]
        elif field_name == 'ipCidrRange':
          ip_cidr_range = field_value
        elif field_name == 'region':
          subnet_region = field_value.split('/')[-1]

      net = ipaddress.ip_network(ip_cidr_range)
      # Note that 4 IP addresses are reserved by GCP in all subnets
      # Source: https://cloud.google.com/vpc/docs/subnets#reserved_ip_addresses_in_every_subnet
      total_ip_addresses = int(net.num_addresses) - 4

      if project_id not in subnet_dict:
        subnet_dict[project_id] = {}
      subnet_dict[project_id][f"{subnet_region}/{subnet_name}"] = {
          'name': subnet_name,
          'region': subnet_region,
          'ip_cidr_range': ip_cidr_range,
          'total_ip_addresses': total_ip_addresses,
          'used_ip_addresses': 0,
          'network_name': network_name
      }

  return subnet_dict


def compute_subnet_utilization_vms(config, read_mask, all_subnets_dict):
  '''
    Counts VMs using private IPs in the different subnets.
      Parameters:
        config (dict): Dict containing config like clients and limits
        read_mask (FieldMask): read_mask to get additional metadata from Cloud Asset Inventory
        all_subnets_dict (dict): Dict containing the information for each subnets in the GCP organization
      Returns:
        None
  '''
  response_vm = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/Instance"],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  # Counting IP addresses for GCE instances (VMs)
  for asset in response_vm:
    for versioned in asset.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        # TODO: Handle multi-NIC
        if field_name == 'networkInterfaces':
          response_dict = MessageToDict(list(field_value._pb)[0])
          # Subnet self link:
          # https://www.googleapis.com/compute/v1/projects/<project_id>/regions/<subnet_region>/subnetworks/<subnet_name>
          subnet_region = response_dict['subnetwork'].split('/')[-3]
          subnet_name = response_dict['subnetwork'].split('/')[-1]
          # Network self link:
          # https://www.googleapis.com/compute/v1/projects/<project_id>/global/networks/<network_name>
          project_id = response_dict['network'].split('/')[6]
          network_name = response_dict['network'].split('/')[-1]

          all_subnets_dict[project_id][f"{subnet_region}/{subnet_name}"][
              'used_ip_addresses'] += 1


def compute_subnet_utilization_ilbs(config, read_mask, all_subnets_dict):
  '''
    Counts ILBs using private IPs in the different subnets.
      Parameters:
        config (dict): Dict containing config like clients and limits
        read_mask (FieldMask): read_mask to get additional metadata from Cloud Asset Inventory
        all_subnets_dict (dict): Dict containing the information for each subnets in the GCP organization
      Returns:
        None
  '''
  response_ilb = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/ForwardingRule"],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response_ilb:
    internal = False
    psc = False
    project_id = ''
    subnet_name = ''
    subnet_region = ''
    address = ''
    network = ''
    for versioned in asset.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if 'loadBalancingScheme' in field_name and field_value in [
            'INTERNAL', 'INTERNAL_MANAGED'
        ]:
          internal = True
        # We want to count only accepted PSC endpoint Forwarding Rule
        # If the PSC endpoint Forwarding Rule is pending, we will count it in the reserved IP addresses
        elif field_name == 'pscConnectionStatus' and field_value == 'ACCEPTED':
          psc = True
        elif field_name == 'IPAddress':
          address = field_value
        elif field_name == 'network':
          project_id = field_value.split('/')[6]
          network = field_value.split('/')[-1]
        elif 'subnetwork' in field_name:
          subnet_name = field_value.split('/')[-1]
          subnet_region = field_value.split('/')[-3]

    if internal:
      all_subnets_dict[project_id][f"{subnet_region}/{subnet_name}"][
          'used_ip_addresses'] += 1
    elif psc:
      # PSC endpoint asset doesn't contain the subnet information in Asset Inventory
      # We need to find the correct subnet with IP address matching
      ip_address = ipaddress.ip_address(address)
      for subnet_key, subnet_dict in all_subnets_dict[project_id].items():
        if subnet_dict["network_name"] == network:
          if ip_address in ipaddress.ip_network(subnet_dict['ip_cidr_range']):
            all_subnets_dict[project_id][subnet_key]['used_ip_addresses'] += 1


def compute_subnet_utilization_addresses(config, read_mask, all_subnets_dict):
  '''
    Counts reserved IP addresses in the different subnets.
      Parameters:
        config (dict): Dict containing config like clients and limits
        read_mask (FieldMask): read_mask to get additional metadata from Cloud Asset Inventory
        all_subnets_dict (dict): Dict containing the information for each subnets in the GCP organization
      Returns:
        None
  '''
  response_reserved_ips = config["clients"][
      "asset_client"].search_all_resources(
          request={
              "scope": f"organizations/{config['organization']}",
              "asset_types": ["compute.googleapis.com/Address"],
              "read_mask": read_mask,
              "page_size": config["page_size"],
          })

  # Counting IP addresses for GCE Reserved IPs (ex: PSC, Cloud DNS Inbound policies, reserved GCE IPs)
  for asset in response_reserved_ips:
    purpose = ""
    status = ""
    project_id = ""
    network_name = ""
    subnet_name = ""
    subnet_region = ""
    address = ""
    prefixLength = ""
    address_name = ""
    for versioned in asset.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == 'name':
          address_name = field_value
        if field_name == 'purpose':
          purpose = field_value
        elif field_name == 'region':
          subnet_region = field_value.split('/')[-1]
        elif field_name == 'status':
          status = field_value
        elif field_name == 'address':
          address = field_value
        elif field_name == 'network':
          network_name = field_value.split('/')[-1]
          project_id = field_value.split('/')[6]
        elif field_name == 'subnetwork':
          subnet_name = field_value.split('/')[-1]
          project_id = field_value.split('/')[6]
        elif field_name == 'prefixLength':
          prefixLength = field_value

    # Rserved IP addresses for GCE instances or PSC Forwarding Rule PENDING state
    if purpose == "GCE_ENDPOINT" and status == "RESERVED":
      all_subnets_dict[project_id][f"{subnet_region}/{subnet_name}"][
          'used_ip_addresses'] += 1
    # Cloud DNS inbound policy
    elif purpose == "DNS_RESOLVER":
      all_subnets_dict[project_id][f"{subnet_region}/{subnet_name}"][
          'used_ip_addresses'] += 1
    # PSA Range for Cloud SQL, MemoryStore, etc.
    elif purpose == "VPC_PEERING":
      ip_range = f"{address}/{int(prefixLength)}"
      net = ipaddress.ip_network(ip_range)
      # Note that 4 IP addresses are reserved by GCP in all subnets
      # Source: https://cloud.google.com/vpc/docs/subnets#reserved_ip_addresses_in_every_subnet
      total_ip_addresses = int(net.num_addresses) - 4
      all_subnets_dict[project_id][f"psa/{address_name}"] = {
          'name': f"psa/{address_name}",
          'region': subnet_region,
          'ip_cidr_range': ip_range,
          'total_ip_addresses': total_ip_addresses,
          'used_ip_addresses': 0,
          'network_name': network_name
      }


def compute_subnet_utilization_redis(config, read_mask, all_subnets_dict):
  '''
    Counts Redis (Memorystore) instances using private IPs in the different subnets.
      Parameters:
        config (dict): Dict containing config like clients and limits
        read_mask (FieldMask): read_mask to get additional metadata from Cloud Asset Inventory
        all_subnets_dict (dict): Dict containing the information for each subnets in the GCP organization
      Returns:
        None
  '''
  response_redis = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["redis.googleapis.com/Instance"],
          "read_mask": read_mask,
          "page_size": config["page_size"],
      })

  for asset in response_redis:
    ip_range = ""
    connect_mode = ""
    network_name = ""
    project_id = ""
    region = ""
    for versioned in asset.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == 'locationId':
          region = field_value[0:-2]
        if field_name == 'authorizedNetwork':
          network_name = field_value.split('/')[-1]
          project_id = field_value.split('/')[1]
        if field_name == 'reservedIpRange':
          ip_range = field_value
        if field_name == 'connectMode':
          connect_mode = field_value

    # Only handling PSA for Redis for now
    if connect_mode == "PRIVATE_SERVICE_ACCESS":
      redis_ip_range = ipaddress.ip_network(ip_range)
      for subnet_key, subnet_dict in all_subnets_dict[project_id].items():
        if subnet_dict["network_name"] == network_name:
          # Reddis instance asset doesn't contain the subnet information in Asset Inventory
          # We need to find the correct subnet range with IP address matching to compute the utilization
          if redis_ip_range.overlaps(
              ipaddress.ip_network(subnet_dict['ip_cidr_range'])):
            all_subnets_dict[project_id][subnet_key][
                'used_ip_addresses'] += redis_ip_range.num_addresses
            all_subnets_dict[project_id][subnet_key]['region'] = region


def compute_subnet_utilization(config, all_subnets_dict):
  '''
    Counts resources (VMs, ILBs, reserved IPs) using private IPs in the different subnets.
      Parameters:
        config (dict): Dict containing config like clients and limits
        all_subnets_dict (dict): Dict containing the information for each subnets in the GCP organization
      Returns:
        None
  '''
  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  compute_subnet_utilization_vms(config, read_mask, all_subnets_dict)
  compute_subnet_utilization_ilbs(config, read_mask, all_subnets_dict)
  compute_subnet_utilization_addresses(config, read_mask, all_subnets_dict)
  # TODO: Other PSA services such as FileStore, Cloud SQL
  compute_subnet_utilization_redis(config, read_mask, all_subnets_dict)

  # TODO: Handle secondary ranges and count GKE pods


def get_subnets(config, metrics_dict):
  '''
    Writes all subnet metrics to custom metrics.

      Parameters:
        config (dict): The dict containing config like clients and limits
      Returns:
        None
  '''

  all_subnets_dict = get_all_subnets(config)
  # Updates all_subnets_dict with the IP utilization info
  compute_subnet_utilization(config, all_subnets_dict)

  timestamp = time.time()
  for project_id in config["monitored_projects"]:
    if project_id not in all_subnets_dict:
      continue
    for subnet_dict in all_subnets_dict[project_id].values():
      ip_utilization = 0
      if subnet_dict['used_ip_addresses'] > 0:
        ip_utilization = subnet_dict['used_ip_addresses'] / subnet_dict[
            'total_ip_addresses']

      # Building unique identifier with subnet region/name
      subnet_id = f"{subnet_dict['region']}/{subnet_dict['name']}"
      metric_labels = {
          'project': project_id,
          'network_name': subnet_dict['network_name'],
          'subnet_id': subnet_id
      }
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]["ip_usage_per_subnet"]
          ["usage"]["name"], subnet_dict['used_ip_addresses'], metric_labels,
          timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]["ip_usage_per_subnet"]
          ["limit"]["name"], subnet_dict['total_ip_addresses'], metric_labels,
          timestamp=timestamp)
      metrics.append_data_to_series_buffer(
          config, metrics_dict["metrics_per_subnet"]["ip_usage_per_subnet"]
          ["utilization"]["name"], ip_utilization, metric_labels,
          timestamp=timestamp)

    print("Buffered metrics for subnet ip utilization for VPCs in project",
          project_id)
