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


def _psa_range_sqlinstances(resources):
  'Returns counts of Cloud SQL instances per PSA range.'
  for sql_instance in resources['sqlinstances'].values():
    # Get the private IP
    sql_instance_private_ip = None
    for ip in sql_instance['ipAddresses']:
      if ip['type'] == 'PRIVATE':
        sql_instance_private_ip = ip['ipAddress']
    if not sql_instance_private_ip:
      continue

    # Using 1 IP for the Cloud SQL instance + 1 IP for the ILB in front
    # + 1 other IP if availabilityType == 'REGIONAL' (additional instance for HA)
    nb_ips = 3 if sql_instance['availabilityType'] == 'REGIONAL' else 2

    # Need to find the correct PSA range matching
    for psa_range in resources['global_addresses'].values():
      psa_range_ip = ipaddress.ip_network(psa_range['address'] + '/' + str(psa_range['prefixLength']))
      # Found matching PSA range for our Cloud SQL instance
      if ipaddress.ip_address(sql_instance_private_ip) in psa_range_ip:
        yield psa_range['self_link'], nb_ips
        break


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio timeseries for addresses by PSA ranges.'
  LOGGER.info('timeseries')
  # return descriptors
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'network/psa/{dtype}', name,
                           ('project', 'network', 'subnetwork'),
                           dtype.endswith('ratio'))
  # aggregate per-resource counts in total per psa-range counts
  psa_ranges = {
      k: ipaddress.ip_network(v['address'] + '/' + str(v['prefixLength']))
      for k, v in resources['global_addresses'].items()
  }

  psa_counts = {k: 0 for k in resources['global_addresses']}
  # TODO: Later we need to add MemoryStore, Filestore, etc.
  counters = itertools.chain(_psa_range_sqlinstances(resources))
  for psa_self_link, count in counters:
    psa_counts[psa_self_link] += count

  for psa_self_link, count in psa_counts.items():
    max_ips = psa_ranges[psa_self_link].num_addresses - 4
    psa_range = resources['global_addresses'][psa_self_link]
    labels = {
        'network': psa_range['network'],
        'project': psa_range['project_id'],
        'psa_range_name': psa_range['name']
    }
    yield TimeSeries('network/psa/addresses_available', max_ips, labels)
    yield TimeSeries('network/psa/addresses_used', count, labels)
    yield TimeSeries('network/psa/addresses_used_ratio',
                     0 if count == 0 else count / max_ips, labels)