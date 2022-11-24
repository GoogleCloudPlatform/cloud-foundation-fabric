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

import logging

from . import TimeSeries, register_timeseries

LOGGER = logging.getLogger('net-dash.timeseries.firewall-policies')
TUPLE_LIMIT = 2000


@register_timeseries
def timeseries(resources):
  'Derive network timeseries for firewall policies.'
  LOGGER.info('timeseries')
  for v in resources['firewall_policies'].values():
    tuples = int(v['num_tuples'])
    labels = {'parent': v['parent'], 'name': v['name']}
    yield TimeSeries('firewall_policies/tuples_used', tuples, labels)
    yield TimeSeries('firewall_policies/tuples_available', TUPLE_LIMIT, labels)
    yield TimeSeries('firewall_policies/tuples_used_ratio',
                     tuples / TUPLE_LIMIT, labels)
