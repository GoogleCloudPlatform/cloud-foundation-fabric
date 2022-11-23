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

import logging
import urllib.parse

from . import HTTPRequest, Level, Resource, register_init, register_discovery
from .utils import parse_cai_results

# https://content-cloudasset.googleapis.com/v1/organizations/436789450919/assets?contentType=RESOURCE&assetTypes=compute.googleapis.com/Network

CAI_URL = ('https://content-cloudasset.googleapis.com/v1'
           '/organizations/{organization}/assets'
           '?contentType=RESOURCE&{asset_types}&pageSize=500')
LOGGER = logging.getLogger('net-dash.discovery.cai-compute')
TYPES = {
    'addresses': 'Address',
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


def _handle_discovery(resources, response, data):
  'Process discovery data.'
  LOGGER.info('discovery handle request')
  for result in parse_cai_results(data, 'cai-compute', method='list'):
    resource = _handle_resource(resources, result['resource'])
    if not resource:
      continue
    yield resource
  page_token = data.get('nextPageToken')
  if page_token:
    LOGGER.info('requesting next page')
    url = _url(resources)
    yield HTTPRequest(f'{url}&pageToken={page_token}', {}, None)


def _handle_resource(resources, data):
  attrs = data['data']
  resource_name = NAMES[data['discoveryName']]
  resource = {
      'id': attrs['id'],
      'name': attrs['name'],
      'self_link': _self_link(attrs['selfLink'])
  }
  parent_data = _get_parent(data['parent'], resources)
  if not parent_data:
    LOGGER.info(f'{resource["self_link"]} outside perimeter')
    return
  resource.update(parent_data)
  func = globals().get(f'_handle_{resource_name}')
  if not callable(func):
    raise SystemExit(f'specialized function missing for {resource_name}')
  extra_attrs = func(resource, attrs)
  if not extra_attrs:
    return
  resource.update(extra_attrs)
  return Resource(resource_name, resource['self_link'], resource)


def _handle_addresses(resource, data):
  'Handle address type resource data.'
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


def _handle_firewall_policies(resource, data):
  'Handle firewall policy type resource data.'
  return {
      'num_rules': len(data.get('rules', [])),
      'num_tuples': data.get('ruleTupleCount', 0)
  }


def _handle_firewall_rules(resource, data):
  'Handle firewall type resource data.'
  return {'network': _self_link(data['network'])}


def _handle_forwarding_rules(resource, data):
  'Handle forwarding_rules type resource data.'
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
  'Handle instance type resource data.'
  if data['status'] != 'RUNNING':
    return
  networks = [{
      'network': _self_link(i['network']),
      'subnetwork': _self_link(i['subnetwork'])
  } for i in data.get('networkInterfaces', [])]
  return {'zone': data['zone'], 'networks': networks}


def _handle_networks(resource, data):
  'Handle network type resource data.'
  peerings = [{
      'active': p['state'] == 'ACTIVE',
      'name': p['name'],
      'network': _self_link(p['network']),
      'project_id': _self_link(p['network']).split('/')[1]
  } for p in data.get('peerings', [])]
  subnets = [_self_link(s) for s in data.get('subnetworks', [])]
  return {'peerings': peerings, 'subnetworks': subnets}


def _handle_routers(resource, data):
  'Handle router type resource data.'
  return {
      'network': _self_link(data['network']),
      'region': data['region'].split('/')[-1]
  }


def _handle_routes(resource, data):
  'Handle route type resource data.'
  hop = [
      a.replace('nextHop', '').lower() for a in data if a.startswith('nextHop')
  ]
  return {'next_hop_type': hop[0], 'network': _self_link(data['network'])}


def _handle_subnetworks(resource, data):
  'Handle subnetwork type resource data.'
  secondary_ranges = [{
      'name': s['rangeName'],
      'cidr_range': s['ipCidrRange']
  } for s in data.get('secondaryIpRanges', [])]
  return {
      'cidr_range': data['ipCidrRange'],
      'network': _self_link(data['network']),
      'purpose': data.get('purpose'),
      'region': data['region']
  }


def _self_link(s):
  'Remove initial part from self links.'
  return s.replace('https://www.googleapis.com/compute/v1/', '')


def _get_parent(parent, resources):
  'Extract and return resource parent.'
  parent_type, parent_id = parent.split('/')[-2:]
  if parent_type == 'projects':
    project = resources['projects:number'].get(parent_id)
    if project:
      return {'project_id': project['project_id'], 'project_number': parent_id}
  if parent_type == 'folders':
    if parent_id in resources['config:folders']:
      return {'parent': f'{parent_type}/{parent_id}'}
  if resources['organization'] == int(parent_id):
    return {'parent': f'{parent_type}/{parent_id}'}


def _url(resources):
  'Return discovery URL'
  organization = resources['config:organization']
  asset_types = '&'.join(
      'assetTypes=compute.googleapis.com/{}'.format(urllib.parse.quote(t))
      for t in TYPES.values())
  return CAI_URL.format(organization=organization, asset_types=asset_types)


@register_init
def init(resources):
  'Prepare the shared datastructures for asset types managed here.'
  LOGGER.info('init')
  for name in TYPES:
    if name not in resources:
      resources[name] = {}


@register_discovery(Level.PRIMARY, 10)
def start_discovery(resources, response=None, data=None):
  'Start discovery by returning the asset list URL for asset types.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  if response is None:
    yield HTTPRequest(_url(resources), {}, None)
  else:
    for result in _handle_discovery(resources, response, data):
      yield result
