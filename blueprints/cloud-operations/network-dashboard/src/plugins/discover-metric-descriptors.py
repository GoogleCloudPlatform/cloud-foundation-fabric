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
'''Discover existing network dashboard metric descriptors.

Populating this data allows the tool to later compute which metric descriptors
need to be created.
'''

import logging
import urllib.parse

from . import HTTPRequest, Level, Resource, register_init, register_discovery
from .utils import parse_page_token

LOGGER = logging.getLogger('net-dash.discovery.metrics')
NAME = 'metric-descriptors'

URL = ('https://content-monitoring.googleapis.com/v3/projects'
       '/{}/metricDescriptors'
       '?filter=metric.type%3Dstarts_with(%22custom.googleapis.com%2F{}%22)'
       '&pageSize=500')


def _handle_discovery(resources, response, data):
  'Processes monitoring API response and parses descriptor data.'
  LOGGER.info('discovery handle request')
  descriptors = data.get('metricDescriptors')
  if not descriptors:
    LOGGER.info('no descriptors found')
    return
  for d in descriptors:
    yield Resource(NAME, d['type'], {})
  next_url = parse_page_token(data, response.request.url)
  if next_url:
    LOGGER.info('discovery next url')
    yield HTTPRequest(next_url, {}, None)


@register_init
def init(resources):
  'Prepares datastructure in the shared resource map.'
  LOGGER.info('init')
  resources.setdefault(NAME, {})


@register_discovery(Level.CORE, 99)
def start_discovery(resources, response=None, data=None):
  'Plugin entry point, triggers discovery and handles requests and responses.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  project_id = resources['config:monitoring_project']
  type_root = resources['config:monitoring_root']
  url = URL.format(urllib.parse.quote_plus(project_id),
                   urllib.parse.quote_plus(type_root))
  if response is None:
    yield HTTPRequest(url, {}, None)
  else:
    for result in _handle_discovery(resources, response, data):
      yield result
