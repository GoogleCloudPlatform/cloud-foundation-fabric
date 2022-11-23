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

LIMITS = {
    'PEERINGS_PER_NETWORK': 25,
    'INTERNAL_FORWARDING_RULES_PER_NETWORK': 500,
    'SUBNET_RANGES_PER_NETWORK': 300,
    'DYNAMIC_ROUTES_PER_PEERING_GROUP': 300,
    'STATIC_ROUTES_PER_PEERING_GROUP': 300,
    'INSTANCES_PER_NETWORK_GLOBAL': 15000
}
LOGGER = logging.getLogger('net-dash.timeseries.peerings')

# def _static(resources):
#   'Derive network and project timeseries for static routes.'
#   filter = lambda v: v['next_hop_type'] in ('peering', 'network')
#   routes = itertools.filterfalse(filter, resources['routes'].values())
#   grouped = itertools.groupby(routes, lambda v: v['network'])
#   project_counts = {}
#   for network_id, elements in grouped:
#     network = resources['networks'].get(network_id)
#     count = len(list(elements))
#     labels = {'project': network['project_id'], 'network': network['name']}
#     yield TimeSeries('network/routes_static_used', count, labels)
#     project_counts[network['project_id']] = project_counts.get(
#         network['project_id'], 0) + count
#   for project_id, count in project_counts.items():
#     labels = {'project': project_id}
#     quota = resources['quota'][project_id]
#     limit = quota.get('ROUTES', LIMITS['ROUTES'])
#     yield TimeSeries('project/routes_static_used', count, labels)
#     yield TimeSeries('project/routes_static_available', limit, labels)
#     yield TimeSeries('project/routes_static_used_ratio', count / limit, labels)


@register_timeseries
def timeseries(resources):
  'Yield timeseries.'
  LOGGER.info('timeseries')
  return
  yield
