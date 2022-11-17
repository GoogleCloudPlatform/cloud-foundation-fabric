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

from . import Level, register_init, register_discovery
from .utils import dirty_mp_request, dirty_mp_response

LOGGER = logging.getLogger('net-dash.discovery.compute-quota')
NAME = 'quota'

API_GLOBAL_URL = '/compute/v1/projects/{}'
API_REGION_URL = '/compute/v1/projects/{}/regions/{}'


def _handle_discovery(resources, response):
  LOGGER.info('discovery handle request')
  content_type = response.headers['content-type']
  for part in dirty_mp_response(content_type, response.content):
    kind = part.get('kind')
    quota = part.get('quotas')
    self_link = part.get('selfLink')
    if not self_link:
      logging.warn('invalid quota response')
    self_link = self_link.split('/')
    if kind == 'compute#project':
      project_id = self_link[-1]
      region = 'global'
    elif kind == 'compute#region':
      project_id = self_link[-3]
      region = self_link[-1]
    project_quota = resources[NAME].setdefault(project_id, {})
    project_quota[region] = quota
  yield


@register_init
def init(resources):
  LOGGER.info('init')
  if NAME not in resources:
    resources[NAME] = {}


@register_discovery(_handle_discovery, Level.DERIVED, 0)
def start_discovery(resources):
  LOGGER.info('discovery start')
  # TODO: split in batches
  yield dirty_mp_request(
      [API_GLOBAL_URL.format(p) for p in resources['projects']])
