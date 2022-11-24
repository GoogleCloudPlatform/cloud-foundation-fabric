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

from . import HTTPRequest, Level, Resource, register_init, register_discovery
from .utils import parse_page_token, parse_cai_results

LOGGER = logging.getLogger('net-dash.discovery.cai-projects')
NAME = 'projects'
TYPE = 'cloudresourcemanager.googleapis.com/Project'

CAI_URL = (
    'https://content-cloudasset.googleapis.com/v1p1beta1'
    '/{}/resources:searchAll'
    f'?assetTypes=cloudresourcemanager.googleapis.com/Project&pageSize=500')


def _handle_discovery(resources, response, data):
  LOGGER.info('discovery handle request')
  for result in parse_cai_results(data, NAME, TYPE):
    data = {
        'number': result['project'].split('/')[1],
        'project_id': result['displayName']
    }
    yield Resource('projects', data['project_id'], data)
    yield Resource('projects:number', data['number'], data)
  next_url = parse_page_token(data, response.request.url)
  if next_url:
    LOGGER.info('discovery next url')
    yield HTTPRequest(next_url, {}, None)


@register_init
def init(resources):
  LOGGER.info('init')
  if NAME not in resources:
    resources[NAME] = {}
  if 'project:numbers' not in resources:
    resources['projects:number'] = {}


@register_discovery(Level.CORE, 0)
def start_discovery(resources, response=None, data=None):
  LOGGER.info(f'discovery (has response: {response is not None})')
  if response is None:
    for v in resources['config:projects']:
      yield HTTPRequest(CAI_URL.format(f'projects/{v}'), {}, None)
    for v in resources['config:folders']:
      yield HTTPRequest(CAI_URL.format(f'folders/{v}'), {}, None)
  else:
    for result in _handle_discovery(resources, response, data):
      yield result
