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
'Prepares descriptors and timeseries for peering group metrics.'

import itertools
import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'forwarding_rules_l4_available':
        'L4 fwd rules limit per peering group',
    'forwarding_rules_l4_used':
        'L4 fwd rules used per peering group',
    'forwarding_rules_l4_used_ratio':
        'L4 fwd rules used ratio per peering group',
    'forwarding_rules_l7_available':
        'L7 fwd rules limit per peering group',
    'forwarding_rules_l7_used':
        'L7 fwd rules used per peering group',
    'forwarding_rules_l7_used_ratio':
        'L7 fwd rules used ratio per peering group',
    'instances_available':
        'Instance limit per peering group',
    'instances_used':
        'Instance used per peering group',
    'instances_used_ratio':
        'Instance used ratio per peering group',
    'routes_dynamic_available':
        'Dynamic route limit per peering group',
    'routes_dynamic_used':
        'Dynamic route used per peering group',
    'routes_dynamic_used_ratio':
        'Dynamic route used ratio per peering group',
    'routes_static_available':
        'Static route limit per peering group',
    'routes_static_used':
        'Static route used per peering group',
    'routes_static_used_ratio':
        'Static route used ratio per peering group',
}
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
  'Returns count of L4 forwarding rules for specified network ids.'
  return len([
      r for r in resources['forwarding_rules'].values() if
      r['network'] in network_ids and r['load_balancing_scheme'] == 'INTERNAL'
  ])


def _count_forwarding_rules_l7(resources, network_ids):
  'Returns count of L7 forwarding rules for specified network ids.'
  return len([
      r for r in resources['forwarding_rules'].values()
      if r['network'] in network_ids and
      r['load_balancing_scheme'] == 'INTERNAL_MANAGED'
  ])


def _count_instances(resources, network_ids):
  'Returns count of instances for specified network ids.'
  count = 0
  for i in resources['instances'].values():
    if any(n['network'] in network_ids for n in i['networks']):
      count += 1
  return count


def _count_routes_static(resources, network_ids):
  'Returns count of static routes for specified network ids.'
  return len(
      [r for r in resources['routes'].values() if r['network'] in network_ids])


def _count_routes_dynamic(resources, network_ids):
  'Returns count of dynamic routes for specified network ids.'
  return sum([
      sum(v.values())
      for k, v in resources['routes_dynamic'].items()
      if k in network_ids
  ])


def _get_limit_max(quota, network_id, project_id, resource_name):
  'Returns maximum limit value in project / peering group / network limits.'
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
  'Computes and returns peering group limit.'
  # reference https://cloud.google.com/vpc/docs/quota#vpc-peering-ilb-example
  # step 1 - vpc_max = max(vpc limit, pg limit)
  vpc_max = _get_limit_max(quota, network['self_link'], network['project_id'],
                           resource_name)
  # step 2 - peers_max = [max(vpc limit, pg limit) for v in peered vpcs]
  # step 3 - peers_min = min(peers_max)
  peers_min = min([
      _get_limit_max(quota, p['network'], p['project_id'], resource_name)
      for p in network['peerings']
  ])
  # step 4 - max(vpc_max, peers_min)
  return max([vpc_max, peers_min])


def _peering_group_timeseries(resources, network):
  'Computes and returns peering group timeseries for network.'
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
  'Returns peering group timeseries for all networks.'
  LOGGER.info('timeseries')
  # returns metric descriptors
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'peering_group/{dtype}', name,
                           ('project', 'network'), dtype.endswith('ratio'))
  # chain timeseries for each network and return each one individually
  results = itertools.chain(*(_peering_group_timeseries(resources, n)
                              for n in resources['networks'].values()))
  for result in results:
    yield result
