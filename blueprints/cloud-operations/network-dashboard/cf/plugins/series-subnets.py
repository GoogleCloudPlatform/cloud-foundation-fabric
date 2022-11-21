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

import collections
import ipaddress
import itertools
import logging

from . import TimeSeries, register_timeseries

LOGGER = logging.getLogger('net-dash.timeseries.subnets')


def _subnet_addresses(resources):
  'Return partial counts of addresses per subnetwork.'
  for v in resources['addresses'].values():
    if v['status'] != 'RESERVED':
      continue
    if v['purpose'] in ('GCE_ENDPOINT', 'DNS_RESOLVER'):
      yield v['subnetwork'], 1


def _subnet_forwarding_rules(resources):
  'Return partial counts of forwarding rules per subnetwork.'
  for v in resources['forwarding_rules'].values():
    if v['load_balancing_scheme'].startswith('INTERNAL'):
      yield v['subnetwork'], 1
      continue
    if v['psc_accepted']:
      network = resources['networks'].get(v['network'])
      if not network:
        LOGGER.warn(f'PSC address for missing network {v["network"]}')
        continue
      address = ipaddress.ip_address(v['address'])
      for subnet_self_link in network['subnetworks']:
        subnet = resources['subnetworks'][subnet_self_link]
        cidr_range = ipaddress.ip_network(subnet['cidr_range'])
        if address in cidr_range:
          yield subnet_self_link, 1
          break
      continue


def _subnet_instances(resources):
  'Return partial counts of instances per subnetwork.'
  vm_networks = itertools.chain.from_iterable(
      i['networks'] for i in resources['instances'].values())
  return collections.Counter(v['subnetwork'] for v in vm_networks).items()


@register_timeseries
def subnet_timeseries(resources):
  LOGGER.info('timeseries')
  series = {k: 0 for k in resources['subnetworks']}
  counters = itertools.chain(_subnet_addresses(resources),
                             _subnet_forwarding_rules(resources),
                             _subnet_instances(resources))
  for subnet, count in counters:
    series[subnet] += count
  from icecream import ic
  ic(series)
  return
  yield
