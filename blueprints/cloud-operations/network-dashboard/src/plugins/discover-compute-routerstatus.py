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
'''Discovers dynamic route counts via router status.

This plugin depends on the CAI Compute one as it discovers dynamic route
data by parsing router status, and it needs routers to have already been
discovered. It uses batch Compute API requests via the utils functions.
'''

import logging

from . import Level, Resource, register_init, register_discovery
from .utils import batched, poor_man_mp_request, poor_man_mp_response

LOGGER = logging.getLogger('net-dash.discovery.compute-routes-dynamic')
NAME = 'routes_dynamic'

API_URL = '/compute/v1/projects/{}/regions/{}/routers/{}/getRouterStatus'


def _handle_discovery(resources, response):
  'Processes asset batch response and parses router status data.'
  LOGGER.info('discovery handle request')
  content_type = response.headers['content-type']
  routers = [r for r in resources['routers'].values()]
  # process batch response
  for i, part in enumerate(poor_man_mp_response(content_type,
                                                response.content)):
    router = routers[i]
    result = part.get('result')
    if not result:
      LOGGER.info(f'skipping router {router["self_link"]}, no result')
      continue
    bgp_peer_status = result.get('bgpPeerStatus')
    if not bgp_peer_status:
      LOGGER.info(f'skipping router {router["self_link"]}, no bgp peer status')
      continue
    network = result.get('network')
    if not network:
      LOGGER.info(f'skipping router {router["self_link"]}, no bgp peer status')
      continue
    if not network.endswith(router['network']):
      LOGGER.warn(
          f'router network mismatch: got {network} expected {router["network"]}'
      )
      continue
    num_learned_routes = sum(
        int(p.get('numLearnedRoutes', 0)) for p in bgp_peer_status)
    if router['network'] not in resources[NAME]:
      resources[NAME][router['network']] = {}
    yield Resource(NAME, router['network'], num_learned_routes,
                   router['self_link'])
  yield


@register_init
def init(resources):
  'Prepares dynamic routes datastructure in the shared resource map.'
  LOGGER.info('init')
  resources.setdefault(NAME, {})


@register_discovery(Level.DERIVED)
def start_discovery(resources, response=None):
  'Plugin entry point, triggers discovery and handles requests and responses.'
  LOGGER.info(f'discovery (has response: {response is not None})')
  if not response:
    urls = [
        API_URL.format(r['project_id'], r['region'], r['name'])
        for r in resources['routers'].values()
    ]
    if not urls:
      return
    for batch in batched(urls, 10):
      yield poor_man_mp_request(batch)
  else:
    for result in _handle_discovery(resources, response):
      yield result
