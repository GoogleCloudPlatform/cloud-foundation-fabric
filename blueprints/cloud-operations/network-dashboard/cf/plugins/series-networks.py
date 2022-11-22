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

LIMIT = 15000
LOGGER = logging.getLogger('net-dash.timeseries.networks')


@register_timeseries
def timeseries(resources):
  LOGGER.info('timeseries')
  instance_networks = functools.reduce(
      operator.add, [i['networks'] for i in resources['instances'].values()])
  grouped = itertools.groupby(instance_networks, lambda i: i['network'])
  for network_id, elements in grouped:
    network = resources['networks'].get(network_id)
    if not network:
      LOGGER.info(f'out of scope instance network {network_id}')
      continue
    count = len(list(elements))
    labels = {'project': network['project_id'], 'network': network['name']}
    yield TimeSeries('network/instances_used', count, labels)
    yield TimeSeries('network/instances_available', LIMIT, labels)
    yield TimeSeries('network/instances_used_ratio', count / LIMIT, labels)
