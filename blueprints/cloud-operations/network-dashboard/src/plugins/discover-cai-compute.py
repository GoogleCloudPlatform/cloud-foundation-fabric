# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
'''Compute resources discovery from Cloud Asset Inventory.

This plugin handles discovery for Compute resources via a broad org-level
scoped CAI search. Common resource attributes are parsed by a generic handler
function, which then delegates parsing of resource-level attributes to smaller
specialized functions, one per resource type.
'''

import logging

from . import HTTPRequest, Level, Resource, register_init, register_discovery
from .utils import parse_cai_results


CAI_URL = ('https://content-cloudasset.googleapis.com/v1'
           '/{root}/assets'
           '?contentType=RESOURCE&{asset_types}&pageSize=500')
LOGGER = logging.getLogger('net-dash.discovery.cai-compute')
TYPES = {
    'addresses': 'Address',
    'global_addresses': 'GlobalAddress',
    'firewall_policies': 'FirewallPolicy',
    'firewall_rules': 'Firewall',
    'forwarding_rules': 'ForwardingRule',
    'instances': 'Instance',
    'networks': 'Network',
    'subnetworks': 'Subnetwork',
    'routers': 'Router',
    'routes': 'Route',
}
NAMES = {v: k for k, v in TYPES.items()}


def _get_parent(parent, resources):
  'Extracts and returns resource parent and type.'
  parent_type, parent_id = parent.split('/')[-2:]
  if parent_type == 'projects':
    project = resources['projects:number'].get(parent_id)
    if project:
      return {'project_id': project['project_id'], 'project_number': parent_id}
  if parent_type == 'folders':
    if parent_id in resources['folders']:
      return {'parent': f'{parent_type}/{parent_id}'}
  if resources.get('organization') == parent_id:
    return {'parent': f'{parent_type}/{parent_id}'}


def _handle_discovery(resources, response, data):
  'Processes the asset API response and returns parsed resources or next URL.'
  LOGGER.info('discovery handle request')
  for result in parse_cai_results(data, 'cai-compute', method='list'):
    resource = _handle_resource(resources, result['resource'], result['assetType'])
    if not resource:
      continue
    yield resource
  page_token = data.get('nextPageToken')
  if page_token:
    LOGGER.info('requesting next page')
    url = _url(resources)
    yield HTTPRequest(f'{url}&pageToken={page_token}', {}, None)


def _handle_resource(resources, data, assetType):
  'Parses and returns a single resource. Calls resource-level handler.'
  attrs = data['data']
  # general attributes shared by all resource types
  # Using Asset type as the resource_name instead of the discoveryName
  # Because sometimes it doesn't match
  # For example: assetType = GlobalAddress but discoveryName = Address
  resource_name = NAMES[assetType.split('/')[-1]]
  resource = {
      'id': attrs['id'],
      'name': attrs['name'],
      'self_link': _self_link(attrs['selfLink']),
      'assetType': assetType
  }
  # derive parent type and id and skip if parent is not within scope
  parent_data = _get_parent(data['parent'], resources)
  if not parent_data:
    LOGGER.info(f'{resource["self_link"]} outside perimeter')
    LOGGER.debug([
        resources['organization'], resources['folders'],
        resources['projects:number']
    ])
    return
  resource.update(parent_data)
  # gets and calls the resource-level handler for type specific attributes
  func = globals().get(f'_handle_{resource_name}')
  if not callable(func):
    raise SystemExit(f'specialized function missing for {resource_name}')
  extra_attrs = func(resource, attrs)
  if not extra_attrs:
    return
  resource.update(extra_attrs)
  return Resource(resource_name, resource['self_link'], resource)


def _handle_addresses(resource, data):
  'Handles address type resource data.'
  network = data.get('network')
  subnet = data.get('subnetwork')
  return {
      'address': data['address'],
      'internal': data.get('addressType') == 'INTERNAL',
      'purpose': data.get('purpose', ''),
      'status': data.get('status', ''),
      'network': None if not network else _self_link(network),
      'subnetwork': None if not subnet else _self_link(subnet)
  }

def _handle_global_addresses(resource, data):  
  'Handles GlobalAddress type resource data (ex: PSA ranges).'
  network = data.get('network')
  subnet = data.get('subnetwork')
  prefixLength = data.get('prefixLength')
  return {
      'address': data['address'],
      'prefixLength': None if not prefixLength else prefixLength,
      'internal': data.get('addressType') == 'INTERNAL',
      'purpose': data.get('purpose', ''),
      'status': data.get('status', ''),
      'network': None if not network else _self_link(network),
  }

def _handle_firewall_policies(resource, data):
  'Handles firewall policy type resource data.'
  return {
      'num_rules': len(data.get('rules', [])),
      'num_tuples': data.get('ruleTupleCount', 0)
  }


def _handle_firewall_rules(resource, data):
  'Handles firewall type resource data.'
  return {'network': _self_link(data['network'])}


def _handle_forwarding_rules(resource, data):
  'Handles forwarding_rules type resource data.'
  network = data.get('network')
  region = data.get('region')
  subnet = data.get('subnetwork')
  return {
      'address': data.get('IPAddress'),
      'load_balancing_scheme': data.get('loadBalancingScheme', ''),
      'network': None if not network else _self_link(network),
      'psc_accepted': data.get('pscConnectionStatus') == 'ACCEPTED',
      'region': None if not region else region.split('/')[-1],
      'subnetwork': None if not subnet else _self_link(subnet)
  }


def _handle_instances(resource, data):
  'Handles instance type resource data.'
  if data['status'] != 'RUNNING':
    return
  networks = [{
      'network': _self_link(i['network']),
      'subnetwork': _self_link(i['subnetwork'])
  } for i in data.get('networkInterfaces', [])]
  return {'zone': data['zone'], 'networks': networks}


def _handle_networks(resource, data):
  'Handles network type resource data.'
  peerings = [{
      'active': p['state'] == 'ACTIVE',
      'name': p['name'],
      'network': _self_link(p['network']),
      'project_id': _self_link(p['network']).split('/')[1]
  } for p in data.get('peerings', [])]
  subnets = [_self_link(s) for s in data.get('subnetworks', [])]
  return {'peerings': peerings, 'subnetworks': subnets}


def _handle_routers(resource, data):
  'Handles router type resource data.'
  return {
      'network': _self_link(data['network']),
      'region': data['region'].split('/')[-1]
  }


def _handle_routes(resource, data):
  'Handles route type resource data.'
  hop = [
      a.removeprefix('nextHop').lower() for a in data if a.startswith('nextHop')
  ]
  return {'next_hop_type': hop[0], 'network': _self_link(data['network'])}


def _handle_subnetworks(resource, data):
  'Handles subnetwork type resource data.'
  secondary_ranges = [{
      'name': s['rangeName'],
      'cidr_range': s['ipCidrRange']
  } for s in data.get('secondaryIpRanges', [])]
  return {
      'cidr_range': data['ipCidrRange'],
      'network': _self_link(data['network']),
      'purpose': data.get('purpose'),
      'region': data['region'].split('/')[-1],
      'secondary_ranges': secondary_ranges
  }


def _self_link(s):
  'Removes initial part from self links.'
  return s.removeprefix('https://www.googleapis.com/compute/v1/')


def _url(resources):
  'Returns discovery URL'
  discovery_root = resources['config:discovery_root']
  asset_types = '&'.join(
      f'assetTypes=compute.googleapis.com/{t}' for t in TYPES.values())
  return CAI_URL.format(root=discovery_root, asset_types=asset_types)


@register_init
def init(resources):
  'Prepares the datastructures for types managed here in the resource map.'
  LOGGER.info('init')
  for name in TYPES:
    resources.setdefault(name, {})


@register_discovery(Level.PRIMARY, 10)
def start_discovery(resources, response=None, data=None):
  'Plugin entry point, triggers discovery and handles requests and responses.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  if response is None:
    yield HTTPRequest(_url(resources), {}, None)
  else:
    for result in _handle_discovery(resources, response, data):
      yield result
