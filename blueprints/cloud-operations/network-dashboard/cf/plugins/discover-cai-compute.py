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

import json
import logging
import urllib.parse

from . import HTTPRequest, Level, register_init, register_discovery
from .utils import parse_cai_results

# https://content-cloudasset.googleapis.com/v1/organizations/436789450919/assets?contentType=RESOURCE&assetTypes=compute.googleapis.com/Network

CAI_URL = ('https://content-cloudasset.googleapis.com/v1'
           '/organizations/{organization}/assets'
           '?contentType=RESOURCE&{asset_types}&pageSize=500')
LOGGER = logging.getLogger('net-dash.discovery.cai-compute')
TYPES = {
    'addresses': 'Address',
    'firewall_policies': 'FirewallPolicy',
    'firewalls': 'Firewall',
    'forwarding_rules': 'ForwardingRule',
    'instances': 'Instance',
    'networks': 'Network',
    'subnetworks': 'Subnetwork',
    'routers': 'Router',
    'routes': 'Route',
}
NAMES = {v: k for k, v in TYPES.items()}


class Skip(Exception):
  pass


def _handle_discovery(resources, response):
  'Process discovery data.'
  request = response.request
  LOGGER.info('discovery handle request')
  try:
    data = response.json()
  except json.decoder.JSONDecodeError as e:
    LOGGER.critical(f'error decoding URL {request.url}: {e.args[0]}')
    return {}
  for result in parse_cai_results(data, 'cai-compute', method='list'):
    resource = {}
    resource_data = result['resource']
    resource_name = NAMES[resource_data['discoveryName']]
    parent = resource_data['parent']
    if not _set_parent(resource, parent, resources):
      LOGGER.info(f'{result["name"]} outside perimeter')
      continue
    extend_func = globals().get(f'_handle_{resource_name}')
    if not callable(extend_func):
      raise SystemExit(f'specialized function missing for {resource_name}')
    try:
      extend_func(resource, resource_data['data'])
    except Skip:
      continue
    resources[resource_name][resource['self_link']] = resource
  page_token = data.get('nextPageToken')
  if page_token:
    LOGGER.info('requesting next page')
    url = _url(resources)
    yield HTTPRequest(f'{url}&pageToken={page_token}', {}, None)


def _handle_addresses(resource, data):
  'Handle address type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['network'] = _self_link(
      data['network']) if 'network' in data else None
  resource['subnetwork'] = _self_link(
      data['subnetwork']) if 'subnetwork' in data else None
  resource['address'] = data['address']
  resource['internal'] = data.get('addressType') == 'INTERNAL'
  resource['purpose'] = data.get('purpose')


def _handle_firewall_policies(resource, data):
  'Handle firewall policy type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['num_rules'] = len(data.get('rules', []))
  resource['num_tuples'] = data.get('ruleTupleCount', 0)


def _handle_firewalls(resource, data):
  'Handle firewall type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['network'] = _self_link(data['network'])


def _handle_forwarding_rules(resource, data):
  'Handle forwarding_rules type resource data.'
  from icecream import ic
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['region'] = data['region'].split(
      '/')[-1] if 'region' in data else None
  resource['load_balancing_scheme'] = data['loadBalancingScheme']
  resource['address'] = data['IPAddress'] if 'IPAddress' in data else None
  resource['network'] = _self_link(
      data['network']) if 'network' in data else None
  resource['subnetwork'] = _self_link(
      data['subnetwork']) if 'subnetwork' in data else None
  resource['psc'] = True if data.get('pscConnectionStatus') else False


def _handle_instances(resource, data):
  'Handle instance type resource data.'
  if data['status'] != 'RUNNING':
    raise Skip()
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['zone'] = data['zone']
  resource['networks'] = []
  for i in data.get('networkInterfaces', []):
    resource['networks'].append({
        'network': _self_link(i['network']),
        'subnet': _self_link(i['subnetwork'])
    })


def _handle_networks(resource, data):
  'Handle network type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['peerings'] = []
  for p in data.get('peerings', []):
    if p['state'] != 'ACTIVE':
      continue
    resource['peerings'].append({'name': p['name'], 'network': p['network']})
  resource['subnets'] = [_self_link(s) for s in data.get('subnetworks', [])]


def _handle_routers(resource, data):
  'Handle router type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['network'] = _self_link(data['network'])
  resource['region'] = data['region'].split('/')[-1]


def _handle_routes(resource, data):
  'Handle route type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['network'] = _self_link(data['network'])
  hop = [
      a.replace('nextHop', '').lower() for a in data if a.startswith('nextHop')
  ]
  resource['next_hope_type'] = hop[0]


def _handle_subnetworks(resource, data):
  'Handle subnetwork type resource data.'
  resource['id'] = data['id']
  resource['name'] = data['name']
  resource['self_link'] = _self_link(data['selfLink'])
  resource['cidr_range'] = data['ipCidrRange']
  resource['network'] = _self_link(data['network'])
  resource['purpose'] = data.get('purpose')
  resource['region'] = data['region']
  resource['secondary_ranges'] = []
  for s in data.get('secondaryIpRanges', []):
    resource['secondary_ranges'].append({
        'name': s['rangeName'],
        'cidr_range': s['ipCidrRange']
    })


def _self_link(s):
  'Remove initial part from self links.'
  return s.replace('https://www.googleapis.com/compute/v1/', '')


def _set_parent(resource, parent, resources):
  'Extract and set resource parent.'
  parent_type, parent_id = parent.split('/')[-2:]
  update = None
  if parent_type == 'projects':
    project_id = resources['projects:number'].get(parent_id)
    if project_id:
      update = {'project_id': project_id, 'project_number': parent_id}
  elif parent_type == 'folders':
    if int(parent_id) in resources['folders']:
      update = {'parent': f'{parent_type}/{parent_id}'}
  elif parent_type == 'organizations':
    if resources['organization']['id'] == int(parent_id):
      update = {'parent': f'{parent_type}/{parent_id}'}
  if update:
    resource.update(update)
  return update is not None


def _url(resources):
  'Return discovery URL'
  organization = resources['organization']['id']
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


@register_discovery(_handle_discovery, Level.PRIMARY, 10)
def start_discovery(resources):
  'Start discovery by returning the asset list URL for asset types.'
  LOGGER.info('discovery start')
  yield HTTPRequest(_url(resources), {}, None)
