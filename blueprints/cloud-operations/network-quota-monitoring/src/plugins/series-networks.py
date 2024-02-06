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
'''Prepares descriptors and timeseries for network-level metrics.

This plugin computes metrics for a variety of network resource types like
subnets, instances, peerings, etc. It mostly does so by first grouping
resources for a type, and then using a generalized function to derive counts
and ratios and compute the actual timeseries.
'''

import functools
import itertools
import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'forwarding_rules_l4_available': 'L4 fwd rules limit per network',
    'forwarding_rules_l4_used': 'L4 fwd rules used per network',
    'forwarding_rules_l4_used_ratio': 'L4 fwd rules used ratio per network',
    'forwarding_rules_l7_available': 'L7 fwd rules limit per network',
    'forwarding_rules_l7_used': 'L7 fwd rules used per network',
    'forwarding_rules_l7_used_ratio': 'L7 fwd rules used ratio per network',
    'instances_available': 'Instance limit per network',
    'instances_used': 'Instance used per network',
    'instances_used_ratio': 'Instance used ratio per network',
    'peerings_active_available': 'Active peering limit per network',
    'peerings_active_used': 'Active peering used per network',
    'peerings_active_used_ratio': 'Active peering used ratio per network',
    'peerings_total_available': 'Total peering limit per network',
    'peerings_total_used': 'Total peering used per network',
    'peerings_total_used_ratio': 'Total peering used ratio per network',
    'subnets_available': 'Subnet limit per network',
    'subnets_used': 'Subnet used per network',
    'subnets_used_ratio': 'Subnet used ratio per network'
}
LIMITS = {
    'INSTANCES_PER_NETWORK_GLOBAL': 15000,
    'INTERNAL_FORWARDING_RULES_PER_NETWORK': 500,
    'INTERNAL_MANAGED_FORWARDING_RULES_PER_NETWORK': 75,
    'ROUTES': 250,
    'SUBNET_RANGES_PER_NETWORK': 300
}
LOGGER = logging.getLogger('net-dash.timeseries.networks')


def _group_timeseries(name, resources, grouped, limit_name):
  'Generalized function that returns timeseries from data grouped by network.'
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
  'Groups forwarding rules by network/type and returns relevant timeseries.'
  # create two separate iterators filtered by L4 and L7 balancing schemes
  filter = lambda n, v: v['load_balancing_scheme'] != n
  forwarding_rules = resources['forwarding_rules'].values()
  forwarding_rules_l4 = itertools.filterfalse(
      functools.partial(filter, 'INTERNAL'), forwarding_rules)
  forwarding_rules_l7 = itertools.filterfalse(
      functools.partial(filter, 'INTERNAL_MANAGED'), forwarding_rules)
  # group each iterator by network and return timeseries
  grouped_l4 = itertools.groupby(
      sorted(forwarding_rules_l4, key=lambda i: i['network']),
      lambda i: i['network'])
  grouped_l7 = itertools.groupby(
      sorted(forwarding_rules_l7, key=lambda i: i['network']),
      lambda i: i['network'])
  return itertools.chain(
      _group_timeseries('forwarding_rules_l4', resources, grouped_l4,
                        'INTERNAL_FORWARDING_RULES_PER_NETWORK'),
      _group_timeseries('forwarding_rules_l7', resources, grouped_l7,
                        'INTERNAL_MANAGED_FORWARDING_RULES_PER_NETWORK'),
  )


def _instances(resources):
  'Groups instances by network and returns relevant timeseries.'
  instance_networks = itertools.chain.from_iterable(
      i['networks'] for i in resources['instances'].values())
  grouped = itertools.groupby(
      sorted(instance_networks, key=lambda i: i['network']),
      lambda i: i['network'])
  return _group_timeseries('instances', resources, grouped,
                           'INSTANCES_PER_NETWORK_GLOBAL')


def _peerings(resources):
  'Counts peerings by network and returns relevant timeseries.'
  quota = resources['quota']
  for network_id, network in resources['networks'].items():
    labels = {'project': network['project_id'], 'network': network['name']}
    limit = quota.get(network_id, {}).get('PEERINGS_PER_NETWORK', 250)
    p_active = len([p for p in network['peerings'] if p['active']])
    p_total = len(network['peerings'])
    yield TimeSeries('network/peerings_active_used', p_active, labels)
    yield TimeSeries('network/peerings_active_available', limit, labels)
    yield TimeSeries('network/peerings_active_used_ratio', p_active / limit,
                     labels)
    yield TimeSeries('network/peerings_total_used', p_total, labels)
    yield TimeSeries('network/peerings_total_available', limit, labels)
    yield TimeSeries('network/peerings_total_used_ratio', p_total / limit,
                     labels)


def _subnet_ranges(resources):
  'Groups subnetworks by network and returns relevant timeseries.'
  grouped = itertools.groupby(
      sorted(resources['subnetworks'].values(), key=lambda i: i['network']),
      lambda i: i['network'])
  return _group_timeseries('subnets', resources, grouped,
                           'SUBNET_RANGES_PER_NETWORK')


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio timeseries by network for different resources.'
  LOGGER.info('timeseries')
  # return descriptors
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'network/{dtype}', name, ('project', 'network'),
                           dtype.endswith('ratio'))

  # chain iterators from specialized functions and yield combined timeseries
  results = itertools.chain(_forwarding_rules(resources), _instances(resources),
                            _peerings(resources), _subnet_ranges(resources))
  for result in results:
    yield result
