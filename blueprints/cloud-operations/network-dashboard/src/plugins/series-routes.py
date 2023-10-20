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
'Prepares descriptors and timeseries for network-level route metrics.'

import itertools
import logging

from . import MetricDescriptor, TimeSeries, register_timeseries

DESCRIPTOR_ATTRS = {
    'network/routes_dynamic_used':
        'Dynamic routes limit per network',
    'network/routes_dynamic_available':
        'Dynamic routes used per network',
    'network/routes_dynamic_used_ratio':
        'Dynamic routes used ratio per network',
    'network/routes_static_used':
        'Static routes limit per network',
    'project/routes_dynamic_used':
        'Dynamic routes limit per project',
    'project/routes_dynamic_available':
        'Dynamic routes used per project',
    'project/routes_dynamic_used_ratio':
        'Dynamic routes used ratio per project',
    'project/routes_static_used':
        'Static routes limit per project',
    'project/routes_static_available':
        'Static routes used per project',
    'project/routes_static_used_ratio':
        'Static routes used ratio per project'
}
LIMITS = {'ROUTES': 250, 'ROUTES_DYNAMIC': 100}
LOGGER = logging.getLogger('net-dash.timeseries.routes')


def _dynamic(resources):
  'Computes network-level timeseries for dynamic routes.'
  for network_id, router_counts in resources['routes_dynamic'].items():
    network = resources['networks'][network_id]
    count = sum(router_counts.values())
    labels = {'project': network['project_id'], 'network': network['name']}
    limit = LIMITS['ROUTES_DYNAMIC']
    yield TimeSeries('network/routes_dynamic_used', count, labels)
    yield TimeSeries('network/routes_dynamic_available', limit, labels)
    yield TimeSeries('network/routes_dynamic_used_ratio', count / limit, labels)


def _static(resources):
  'Computes network and project-level timeseries for dynamic routes.'
  filter = lambda v: v['next_hop_type'] in ('peering', 'network')
  routes = itertools.filterfalse(filter, resources['routes'].values())
  grouped = itertools.groupby(sorted(routes, key=lambda i: i['network']),
                              lambda i: i['network'])
  project_counts = {}
  for network_id, elements in grouped:
    network = resources['networks'].get(network_id)
    count = len(list(elements))
    labels = {'project': network['project_id'], 'network': network['name']}
    yield TimeSeries('network/routes_static_used', count, labels)
    project_counts[network['project_id']] = project_counts.get(
        network['project_id'], 0) + count
  for project_id, count in project_counts.items():
    labels = {'project': project_id}
    quota = resources['quota'][project_id]['global']
    limit = quota.get('ROUTES', LIMITS['ROUTES'])
    yield TimeSeries('project/routes_static_used', count, labels)
    yield TimeSeries('project/routes_static_available', limit, labels)
    yield TimeSeries('project/routes_static_used_ratio', count / limit, labels)


@register_timeseries
def timeseries(resources):
  'Returns used/available/ratio timeseries by network and project.'
  LOGGER.info('timeseries')
  # return descriptors
  for dtype, name in DESCRIPTOR_ATTRS.items():
    labels = ('project') if dtype.startswith('project') else ('project',
                                                              'network')
    yield MetricDescriptor(dtype, name, labels, dtype.endswith('ratio'))
  # chain static and dynamic route timeseries then return each one individually
  results = itertools.chain(_static(resources), _dynamic(resources))
  for result in results:
    yield result
