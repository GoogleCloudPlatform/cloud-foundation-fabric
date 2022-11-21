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


def _self_link(s):
  'Add initial part to self links.'
  return f'https://www.googleapis.com/compute/v1/{s}'


def _subnet_addresses(resources):
  'Return partial counts of addresses per subnetwork.'
  for v in resources['addresses'].values():
    if v['status'] != 'RESERVED':
      continue
    if v['purpose'] in ('GCE_ENDPOINT', 'DNS_RESOLVER'):
      yield v['subnetwork'], 1


def _subnet_forwarding_rules(resources, subnet_nets):
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
        if address in subnet_nets[subnet_self_link]:
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
  subnet_nets = {
      k: ipaddress.ip_network(v['cidr_range'])
      for k, v in resources['subnetworks'].items()
  }
  series = {k: 0 for k in resources['subnetworks']}
  # TODO: PSA
  counters = itertools.chain(_subnet_addresses(resources),
                             _subnet_forwarding_rules(resources, subnet_nets),
                             _subnet_instances(resources))
  for subnet_self_link, count in counters:
    series[subnet_self_link] += count
  for subnet_self_link, count in series.items():
    subnet = resources['subnetworks'][subnet_self_link]
    labels = {
        'network': _self_link(subnet['network']),
        'project': subnet['project_id'],
        'subnetwork': _self_link(subnet['id'])
    }
    max_ips = subnet_nets[subnet_self_link].num_addresses - 4
    yield TimeSeries('subnets/available_addresses', max_ips, labels)
    yield TimeSeries('subnets/used_addresses', count, labels)
    yield TimeSeries('subnets/used_addresses_ratio',
                     0 if count == 0 else count / max_ips, labels)
