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

import functools
import itertools
import logging
import operator

from . import TimeSeries, register_timeseries

LIMITS = {
    'INSTANCES_PER_NETWORK_GLOBAL': 15000,
    'INTERNAL_FORWARDING_RULES_PER_NETWORK': 500,
    'INTERNAL_MANAGED_FORWARDING_RULES_PER_NETWORK': 75,
    'ROUTES': 250,
    'SUBNET_RANGES_PER_NETWORK': 300
}
LOGGER = logging.getLogger('net-dash.timeseries.networks')


def _group_timeseries(name, resources, grouped, limit_name):
  'Derive and yield timeseries from grouped iterators and limits.'
  for network_id, elements in grouped:
    network = resources['networks'].get(network_id)
    if not network:
      LOGGER.info(f'out of scope {name} network {network_id}')
      continue
    count = len(list(elements))
    labels = {'project': network['project_id'], 'network': network['name']}
    quota = resources['quota'][network['project_id']]['global']
    limit = quota.get(limit_name, LIMITS[limit_name])
    yield TimeSeries(f'network/{name}_used', count, labels)
    yield TimeSeries(f'network/{name}_available', limit, labels)
    yield TimeSeries(f'network/{name}_used_ratio', count / limit, labels)


def _forwarding_rules(resources):
  'Derive network timeseries for forwarding rule utilization.'
  filter = lambda n, v: v['load_balancing_scheme'] != n
  forwarding_rules = resources['forwarding_rules'].values()
  forwarding_rules_l4 = itertools.filterfalse(
      functools.partial(filter, 'INTERNAL'), forwarding_rules)
  forwarding_rules_l7 = itertools.filterfalse(
      functools.partial(filter, 'INTERNAL_MANAGED'), forwarding_rules)
  grouped_l4 = itertools.groupby(forwarding_rules_l4, lambda i: i['network'])
  grouped_l7 = itertools.groupby(forwarding_rules_l7, lambda i: i['network'])
  return itertools.chain(
      _group_timeseries('forwarding_rule_l4', resources, grouped_l4,
                        'INTERNAL_FORWARDING_RULES_PER_NETWORK'),
      _group_timeseries('forwarding_rule_l7', resources, grouped_l7,
                        'INTERNAL_MANAGED_FORWARDING_RULES_PER_NETWORK'),
  )


def _instances(resources):
  'Derive network timeseries for instance utilization.'
  instance_networks = functools.reduce(
      operator.add, [i['networks'] for i in resources['instances'].values()])
  grouped = itertools.groupby(instance_networks, lambda i: i['network'])
  return _group_timeseries('instances', resources, grouped,
                           'INSTANCES_PER_NETWORK_GLOBAL')


def _peerings(resources):
  quota = resources['quota']
  for network_id, network in resources['networks'].items():
    labels = {'project': network['project_id'], 'network': network['name']}
    limit = quota.get(network_id, {}).get('PEERINGS_PER_NETWORK', 250)
    p_active = len([p for p in network['peerings'] if p['active']])
    p_total = len(network['peerings'])
    yield TimeSeries('network/peering_active_used', p_active, labels)
    yield TimeSeries('network/peering_active_available', limit, labels)
    yield TimeSeries('network/peering_active_used_ratio', p_active / limit,
                     labels)
    yield TimeSeries('network/peering_total_used', p_total, labels)
    yield TimeSeries('network/peering_total_available', limit, labels)
    yield TimeSeries('network/peering_total_used_ratio', p_total / limit,
                     labels)


def _subnet_ranges(resources):
  'Derive network timeseries for subnet range utilization.'
  grouped = itertools.groupby(resources['subnetworks'].values(),
                              lambda v: v['network'])
  return _group_timeseries('subnet', resources, grouped,
                           'SUBNET_RANGES_PER_NETWORK')


@register_timeseries
def timeseries(resources):
  'Yield timeseries.'
  LOGGER.info('timeseries')
  return itertools.chain(_forwarding_rules(resources), _instances(resources),
                         _peerings(resources), _subnet_ranges(resources))
