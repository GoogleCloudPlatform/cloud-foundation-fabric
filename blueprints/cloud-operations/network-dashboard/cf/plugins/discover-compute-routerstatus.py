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

from . import Level, Resource, register_init, register_discovery
from .utils import batched, dirty_mp_request, dirty_mp_response

LOGGER = logging.getLogger('net-dash.discovery.compute-routes-dynamic')
NAME = 'routes-dynamic'

API_URL = '/compute/v1/projects/{}/regions/{}/routers/{}/getRouterStatus'


def _handle_discovery(resources, response):
  LOGGER.info('discovery handle request')
  content_type = response.headers['content-type']
  routers = [r for r in resources['routers'].values()]
  for i, part in enumerate(dirty_mp_response(content_type, response.content)):
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
    yield Resource(
        NAME, router['network'],
        resources[NAME].get(router['network'], 0) + num_learned_routes)
  yield


@register_init
def init(resources):
  LOGGER.info('init')
  if NAME not in resources:
    resources[NAME] = {}


@register_discovery(Level.DERIVED)
def start_discovery(resources, response=None):
  LOGGER.info(f'discovery (has response: {response is not None})')
  if not response:
    urls = [
        API_URL.format(r['project_id'], r['region'], r['name'])
        for r in resources['routers'].values()
    ]
    if not urls:
      return
    for batch in batched(urls, 10):
      yield dirty_mp_request(batch)
  else:
    for result in _handle_discovery(resources, response):
      yield result
