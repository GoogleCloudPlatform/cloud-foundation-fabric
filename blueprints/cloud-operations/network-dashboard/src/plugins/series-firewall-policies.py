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
'Prepares descriptors and timeseries for firewall policy resources.'

import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'tuples_used': 'Firewall tuples used per policy',
    'tuples_available': 'Firewall tuples limit per policy',
    'tuples_used_ratio': 'Firewall tuples used ratio per policy'
}
DESCRIPTOR_LABELS = ('parent', 'name')
LOGGER = logging.getLogger('net-dash.timeseries.firewall-policies')
TUPLE_LIMIT = 2000


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio firewall tuples timeseries by policy.'
  LOGGER.info('timeseries')
  for dtype, name in DESCRIPTOR_ATTRS.items():
    yield MetricDescriptor(f'firewall_policy/{dtype}', name, DESCRIPTOR_LABELS,
                           dtype.endswith('ratio'))
  for v in resources['firewall_policies'].values():
    tuples = int(v['num_tuples'])
    labels = {'parent': v['parent'], 'name': v['name']}
    yield TimeSeries('firewall_policy/tuples_used', tuples, labels)
    yield TimeSeries('firewall_policy/tuples_available', TUPLE_LIMIT, labels)
    yield TimeSeries('firewall_policy/tuples_used_ratio', tuples / TUPLE_LIMIT,
                     labels)
