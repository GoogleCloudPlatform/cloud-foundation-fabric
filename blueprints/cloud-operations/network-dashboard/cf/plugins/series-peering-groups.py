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

import itertools
import logging

from . import TimeSeries, register_timeseries

LIMITS = {
    'forwarding_rules_l4': {
        'pg': ('INTERNAL_FORWARDING_RULES_PER_PEERING_GROUP', 500),
        'prj': ('INTERNAL_FORWARDING_RULES_PER_NETWORK', 500)
    },
    'forwarding_rules_l7': {
        'pg': ('INTERNAL_MANAGED_FORWARDING_RULES_PER_PEERING_GROUP', 175),
        'prj': ('INTERNAL_MANAGED_FORWARDING_RULES_PER_NETWORK', 75)
    },
    'instances': {
        'pg': ('INSTANCES_PER_PEERING_GROUP', 15500),
        'prj': ('INSTANCES_PER_NETWORK_GLOBAL', 15000)
    },
    'routes_static': {
        'pg': ('STATIC_ROUTES_PER_PEERING_GROUP', 300),
        'prj': ('ROUTES', 250)
    },
    'routes_dynamic': {
        'pg': ('DYNAMIC_ROUTES_PER_PEERING_GROUP', 300),
        'prj': ('', 100)
    }
}
LOGGER = logging.getLogger('net-dash.timeseries.peerings')


def _count_forwarding_rules_l4(resources, network_ids):
  return len([
      r for r in resources['forwarding_rules'].values() if
      r['network'] in network_ids and r['load_balancing_scheme'] == 'INTERNAL'
  ])


def _count_forwarding_rules_l7(resources, network_ids):
  return len([
      r for r in resources['forwarding_rules'].values()
      if r['network'] in network_ids and
      r['load_balancing_scheme'] == 'INTERNAL_MANAGED'
  ])


def _count_instances(resources, network_ids):
  count = 0
  for i in resources['instances'].values():
    if any(n['network'] in network_ids for n in i['networks']):
      count += 1
  return count


def _count_routes_static(resources, network_ids):
  return len(
      [r for r in resources['routes'].values() if r['network'] in network_ids])


def _count_routes_dynamic(resources, network_ids):
  return sum([
      sum(v.values())
      for k, v in resources['routes_dynamic'].items()
      if k in network_ids
  ])


def _get_limit_max(quota, network_id, project_id, resource_name):
  pg_name, pg_default = LIMITS[resource_name]['pg']
  prj_name, prj_default = LIMITS[resource_name]['prj']
  network_quota = quota.get(network_id, {})
  project_quota = quota.get(project_id, {}).get('global', {})
  return max([
      network_quota.get(pg_name, 0),
      project_quota.get(prj_name, prj_default),
      project_quota.get(pg_name, pg_default)
  ])


def _get_limit(quota, network, resource_name):
  # https://cloud.google.com/vpc/docs/quota#vpc-peering-ilb-example
  # vpc_max = max(vpc limit, pg limit)
  vpc_max = _get_limit_max(quota, network['self_link'], network['project_id'],
                           resource_name)
  # peers_max = [max(vpc limit, pg limit) for v in peered vpcs]
  # peers_min = min(peers_max)
  peers_min = min([
      _get_limit_max(quota, p['network'], p['project_id'], resource_name)
      for p in network['peerings']
  ])
  # max(vpc_max, peers_min)
  return max([vpc_max, peers_min])


def _network_timeseries(resources, network):
  if len(network['peerings']) == 0:
    return
  network_ids = [network['self_link']
                ] + [p['network'] for p in network['peerings']]
  for resource_name in LIMITS:
    limit = _get_limit(resources['quota'], network, resource_name)
    func = globals().get(f'_count_{resource_name}')
    if not func or not callable(func):
      LOGGER.critical(f'no handler for {resource_name} or handler not callable')
      continue
    count = func(resources, network_ids)
    labels = {'project': network['project_id'], 'network': network['name']}
    yield TimeSeries(f'peering_group/{resource_name}_used', count, labels)
    yield TimeSeries(f'peering_group/{resource_name}_available', limit, labels)
    yield TimeSeries(f'peering_group/{resource_name}_used_ratio', count / limit,
                     labels)


@register_timeseries
def timeseries(resources):
  'Yield timeseries.'
  LOGGER.info('timeseries')
  return itertools.chain(*(_network_timeseries(resources, n)
                           for n in resources['networks'].values()))
