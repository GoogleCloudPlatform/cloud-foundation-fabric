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
'Prepares descriptors and timeseries for subnetwork-level metrics.'

import collections
import ipaddress
import itertools
import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'addresses_available': 'Address limit per psa range',
    'addresses_used': 'Addresses used per psa range',
    'addresses_used_ratio': 'Addresses used ratio per psa range'
}
LOGGER = logging.getLogger('net-dash.timeseries.psa')


def _sql_addresses(sql_instances):
  'Returns counts of Cloud SQL instances per PSA range.'
  for v in sql_instances.values():
    if not v['ipAddresses']:
      continue
    # 1 IP for the instance + 1 IP for the ILB + 1 IP if HA
    yield v['ipAddresses'][0], 2 if v['availabilityType'] != 'REGIONAL' else 3


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio timeseries for addresses by PSA ranges.'
  LOGGER.info('timeseries')
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'network/psa/{dtype}', name,
                           ('project', 'network', 'subnetwork'),
                           dtype.endswith('ratio'))
  psa_nets = {
      k: ipaddress.ip_network('{}/{}'.format(v['address'], v['prefixLength']))
      for k, v in resources['global_addresses'].items()
      if v['prefixLength']
  }
  psa_counts = {}
  for address, ip_count in _sql_addresses(resources.get('sql_instances', {})):
    ip_address = ipaddress.ip_address(address)
    for k, v in psa_nets.items():
      if ip_address in v:
        psa_counts[k] = psa_counts.get(k, 0) + ip_count
        break

  for k, v in psa_counts.items():
    max_ips = psa_nets[k].num_addresses - 4
    psa_range = resources['global_addresses'][k]
    labels = {
        'network': psa_range['network'],
        'project': psa_range['project_id'],
        'psa_range': psa_range['name']
    }
    yield TimeSeries('network/psa/addresses_available', max_ips, labels)
    yield TimeSeries('network/psa/addresses_used', v, labels)
    yield TimeSeries('network/psa/addresses_used_ratio',
                     0 if v == 0 else v / max_ips, labels)
