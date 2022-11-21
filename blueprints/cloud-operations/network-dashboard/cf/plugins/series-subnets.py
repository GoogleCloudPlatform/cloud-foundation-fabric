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

import itertools
import logging

from . import TimeSeries, register_timeseries

LOGGER = logging.getLogger('net-dash.timeseries.subnets')


@register_timeseries
def subnet_timeseries(resources, series):
  series = {k: 0 for k, v in resources['subnets']}
  vm_networks = itertools.chain.from_iterable(
      i['networks'] for i in resources['instances'].values())
  for v in vm_networks:
    series[v['subnetwork']] += 1