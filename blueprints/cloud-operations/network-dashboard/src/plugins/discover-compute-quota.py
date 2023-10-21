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
'''Discovers project quota via Compute API and overlay user overrides.

This plugin discovers project quota via batch Compute API requests. Project and
network quotas are then optionally overlaid with custom quota modifiers passed
in as options. Region quota discovery is partially implemented but not active.
'''

import logging

from . import Level, Resource, register_init, register_discovery
from .utils import batched, poor_man_mp_request, poor_man_mp_response

LOGGER = logging.getLogger('net-dash.discovery.compute-quota')
NAME = 'quota'

API_GLOBAL_URL = '/compute/v1/projects/{}'
API_REGION_URL = '/compute/v1/projects/{}/regions/{}'


def _handle_discovery(resources, response):
  'Processes asset batch response and overlays custom quota.'
  LOGGER.info('discovery handle request')
  content_type = response.headers['content-type']
  per_project_quota = resources['config:custom_quota'].get('projects', {})
  # process batch response
  for part in poor_man_mp_response(content_type, response.content):
    kind = part.get('kind')
    quota = {
        q['metric']: int(q['limit'])
        for q in sorted(part.get('quotas', []), key=lambda v: v['metric'])
    }
    self_link = part.get('selfLink')
    if not self_link:
      logging.warn('invalid quota response')
      continue
    self_link = self_link.split('/')
    if kind == 'compute#project':
      project_id = self_link[-1]
      region = 'global'
    elif kind == 'compute#region':
      project_id = self_link[-3]
      region = self_link[-1]
    # custom quota overrides
    for k, v in per_project_quota.get(project_id, {}).get(region, {}).items():
      quota[k] = int(v)
    if project_id not in resources[NAME]:
      resources[NAME][project_id] = {}
    yield Resource(NAME, project_id, quota, region)


@register_init
def init(resources):
  'Prepares quota datastructures in the shared resource map.'
  LOGGER.info('init')
  resources.setdefault(NAME, {})


@register_discovery(Level.DERIVED, 0)
def start_discovery(resources, response=None):
  'Plugin entry point, triggers discovery and handles requests and responses.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  if response is None:
    # TODO: regions
    urls = [API_GLOBAL_URL.format(p) for p in resources['projects']]
    if not urls:
      return
    for batch in batched(urls, 10):
      yield poor_man_mp_request(batch)
  else:
    for result in _handle_discovery(resources, response):
      yield result
  # store custom network-level quota
  per_network_quota = resources['config:custom_quota'].get('networks', {})
  for network_id, overrides in per_network_quota.items():
    quota = {k: int(v) for k, v in overrides.items()}
    yield Resource(NAME, network_id, quota)
