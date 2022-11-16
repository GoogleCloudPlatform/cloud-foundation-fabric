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

from . import *
from .utils import parse_cai_page_token, parse_cai_results


CAI_URL = ('https://content-cloudasset.googleapis.com/v1p1beta1'
           '/organizations/{organization}/resources:searchAll'
           '?{asset_types}&pageSize=500')
PLUGIN_NAME = 'discovery-cai-compute'
TYPES = {
  'networks': 'Network',
  'subnetworks': 'Subnetwork',
  'firewalls': 'Firewall',
  'firewall_policies': 'FirewallPolicy',
  'instances': 'Instance',
  'routes': 'Route',
  'routers': 'Router'}
NAMES = {v:k for k,v in TYPES.items()}


@register(PLUGIN_NAME, Phase.INIT, Step.START)
def init(resources):
  for name in TYPES:
    if name not in resources:
      resources[name] = {}


@register(PLUGIN_NAME, Phase.DISCOVERY, Step.START, Level.PRIMARY, 10)
def start_discovery(resources):
  organization = resources['organization']['id']
  asset_types = '&'.join(
      'assetTypes=compute.googleapis.com/{}'.format(urllib.parse.quote(t))
      for t in TYPES.values())
  yield CAI_URL.format(organization=organization, asset_types=asset_types)


@register(PLUGIN_NAME, Phase.DISCOVERY, Step.END)
def end_discovery(resources, data, url):
  for result in parse_cai_results(data, PLUGIN_NAME):
    name = result['displayName']
    resource_name = NAMES[result['assetType'].split('/')[1]]
    resource = {'name': name}
    try:
      project_number = result['project'].split('/')[1]
      project_id = resources['projects:number'].get(project_number)
    except KeyError:
      pass
    else:
      if not project_id:
        logging.info(f'skipping resource {name} in {project_number}')
        continue
      resource['project_id'] = project_id
      resource['project_number'] = project_number
    match resource_name:
      case 'firewall_policies':
        resource['id'] = result['name'].split('/')[-1]
      case 'subnetworks':
        resource['cidr_range'] = result['additionalAttributes'][0]
        resource['region'] = result['location']
    resources[resource_name][name] = resource
  return parse_cai_page_token(data, url)
