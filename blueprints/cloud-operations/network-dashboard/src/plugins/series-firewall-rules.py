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
'Prepares descriptors and timeseries for firewall rules by project and network.'

import itertools
import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'firewall_rules_used': 'Firewall rules used per project',
    'firewall_rules_available': 'Firewall rules limit per project',
    'firewall_rules_used_ratio': 'Firewall rules used ratio per project',
}
LOGGER = logging.getLogger('net-dash.timeseries.firewall-rules')


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio firewall timeseries by project and network.'
  LOGGER.info('timeseries')
  # return a single descriptor for network as we don't have limits
  yield MetricDescriptor(f'network/firewall_rules_used',
                         'Firewall rules used per network', ('project', 'name'))
  # return used/vailable/ratio descriptors for project
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'project/{dtype}', name, ('project',),
                           dtype.endswith('ratio'))
  # group firewall rules by network then prepare and return timeseries
  grouped = itertools.groupby(
      sorted(resources['firewall_rules'].values(), key=lambda i: i['network']),
      lambda i: i['network'])
  for network_id, rules in grouped:
    count = len(list(rules))
    labels = {
        'name': resources['networks'][network_id]['name'],
        'project': resources['networks'][network_id]['project_id']
    }
    yield TimeSeries('network/firewall_rules_used', count, labels)
  # group firewall rules by project then prepare and return timeseries
  grouped = itertools.groupby(
      sorted(resources['firewall_rules'].values(),
             key=lambda i: i['project_id']), lambda i: i['project_id'])
  for project_id, rules in grouped:
    count = len(list(rules))
    limit = int(resources['quota'][project_id]['global']['FIREWALLS'])
    labels = {'project': project_id}
    yield TimeSeries('project/firewall_rules_used', count, labels)
    yield TimeSeries('project/firewall_rules_available', limit, labels)
    yield TimeSeries('project/firewall_rules_used_ratio', count / limit, labels)
