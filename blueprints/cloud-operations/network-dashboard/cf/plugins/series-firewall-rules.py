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

LOGGER = logging.getLogger('net-dash.timeseries.firewall-rules')


@register_timeseries
def timeseries(resources):
  LOGGER.info('timeseries')
  grouped = itertools.groupby(resources['firewall_rules'].values(),
                              lambda v: v['network'])
  for network_id, rules in grouped:
    count = len(list(rules))
    labels = {
        'network_name': resources['networks'][network_id]['name'],
        'project_id': resources['networks'][network_id]['project_id']
    }
    yield TimeSeries('network/firewalls/used', count, labels)
  grouped = itertools.groupby(resources['firewall_rules'].values(),
                              lambda v: v['project_id'])
  for project_id, rules in grouped:
    count = len(list(rules))
    limit = int(resources['quota'][project_id]['global']['FIREWALLS']['limit'])
    labels = {'project_id': project_id}
    yield TimeSeries('project/firewall_rules_used', count, labels)
    yield TimeSeries('project/firewalls_rules_available', limit, labels)
    yield TimeSeries('project/firewalls_rules_used_ratio', count / limit,
                     labels)
