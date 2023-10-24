# Copyright 2023 Google LLC
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
'''Project and folder discovery from configuration options.

This plugin needs to run first, as it's responsible for discovering nodes that
contain resources: folders and projects contained in the hierarchy passed in
via configuration options. Node resources are fetched from Cloud Asset
Inventory based on explicit id or being part of a folder hierarchy.
'''

import logging

from . import HTTPRequest, Level, Resource, register_init, register_discovery
from .utils import parse_page_token, parse_cai_results

LOGGER = logging.getLogger('net-dash.discovery.cai-nodes')

CAI_URL = ('https://content-cloudasset.googleapis.com/v1p1beta1'
           '/{}/resources:searchAll'
           '?assetTypes=cloudresourcemanager.googleapis.com/Folder'
           '&assetTypes=cloudresourcemanager.googleapis.com/Project'
           '&pageSize=500')


def _handle_discovery(resources, response, data):
  'Processes asset response and returns project resources or next URLs.'
  LOGGER.info('discovery handle request')
  for result in parse_cai_results(data, 'nodes'):
    asset_type = result['assetType'].split('/')[-1]
    name = result['name'].split('/')[-1]
    if asset_type == 'Folder':
      yield Resource('folders', name, {'name': result['displayName']})
    elif asset_type == 'Project':
      number = result['project'].split('/')[1]
      data = {'number': number, 'project_id': name}
      yield Resource('projects', name, data)
      yield Resource('projects:number', number, data)
    else:
      LOGGER.info(f'unknown resource {name}')
  next_url = parse_page_token(data, response.request.url)
  if next_url:
    LOGGER.info('discovery next url')
    yield HTTPRequest(next_url, {}, None)


@register_init
def init(resources):
  'Prepares project datastructures in the shared resource map.'
  LOGGER.info('init')
  resources.setdefault('folders', {})
  resources.setdefault('projects', {})
  resources.setdefault('projects:number', {})


@register_discovery(Level.CORE, 0)
def start_discovery(resources, response=None, data=None):
  'Plugin entry point, triggers discovery and handles requests and responses.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  if response is None:
    # return initial discovery URLs
    if not resources['config:folders'] and not resources['config:projects']:
      LOGGER.info(
          f'No monitored project or folder given, defaulting to discovery root: {resources["config:discovery_root"]}'
      )
      dr_node = resources["config:discovery_root"].split("/")[0]
      dr_value = resources["config:discovery_root"].split("/")[1]
      yield HTTPRequest(CAI_URL.format(f'{dr_node}/{dr_value}'), {}, None)
    for v in resources['config:folders']:
      yield HTTPRequest(CAI_URL.format(f'folders/{v}'), {}, None)
    for v in resources['config:projects']:
      if v not in resources['projects']:
        yield HTTPRequest(CAI_URL.format(f'projects/{v}'), {}, None)
  else:
    # pass the API response to the plugin data handler and return results
    for result in _handle_discovery(resources, response, data):
      yield result
