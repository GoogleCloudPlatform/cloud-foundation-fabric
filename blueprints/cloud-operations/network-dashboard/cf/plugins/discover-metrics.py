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
from .utils import parse_page_token, parse_cai_results

LOGGER = logging.getLogger('net-dash.discovery.metrics')
NAME = 'metrics'

URL = (
    'https://content-monitoring.googleapis.com/v3/projects'
    '/{}/metricDescriptors'
    '?filter=metric.type%3Dstarts_with(%22custom.googleapis.com%2Fnetmon%2F%22)'
    '&pageSize=500')


def _handle_discovery(resources, response):
  LOGGER.info('discovery handle request')
  request = response.request
  try:
    data = response.json()
  except json.decoder.JSONDecodeError as e:
    LOGGER.critical(f'error decoding URL {request.url}: {e.args[0]}')
    return {}
  descriptors = data.get('metricDescriptors')
  if not descriptors:
    LOGGER.info('no descriptors found')
    return
  for d in descriptors:
    resources['metrics'].append(d['type'])
  next_url = parse_page_token(data, request.url)
  if next_url:
    LOGGER.info('discovery next url')
    yield HTTPRequest(next_url, {}, None)


@register_init
def init(resources):
  LOGGER.info('init')
  if 'metrics' not in resources:
    resources['metrics'] = []


@register_discovery(_handle_discovery, Level.CORE, 0)
def start_discovery(resources):
  LOGGER.info('discovery start')
  yield HTTPRequest(
      URL.format(urllib.parse.quote_plus(resources['monitoring_project'])), {},
      None)
