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
'''Cloud SQL resources discovery from Cloud Asset Inventory.

This plugin handles discovery for Cloud SQL resources via a broad org-level
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
LOGGER = logging.getLogger('net-dash.discovery.cloudsql')
TYPES = {
    'sqlinstances': 'Instance',
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
  for result in parse_cai_results(data, 'cloudsql', method='list'):
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
  'Parses and returns a single resource. Calls resource-level handler.'
  attrs = data['data']
  resource_name = "sqlinstances"
  resource = {
      'name': attrs['name'],
      'self_link': _self_link(attrs['selfLink']),
      'ipAddresses': attrs['ipAddresses'],
      'region': attrs['region'],
      'availabilityType': attrs['settings']['availabilityType'],
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
  return Resource(resource_name, resource['self_link'], resource)


def _self_link(s):
  'Removes initial part from self links.'
  return s.removeprefix('https://sqladmin.googleapis.com/sql/v1beta4/')


def _url(resources):
  'Returns discovery URL'
  discovery_root = resources['config:discovery_root']
  asset_types = '&'.join(
      f'assetTypes=sqladmin.googleapis.com/{t}' for t in TYPES.values())
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
