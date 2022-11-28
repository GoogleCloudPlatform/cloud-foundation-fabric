#!/usr/bin/env python3
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
'Network dashboard: create network-related metric timeseries for GCP resources.'

import collections
import json
import logging

import click
import google.auth
import plugins
import plugins.monitoring
import yaml

from google.auth.transport.requests import AuthorizedSession

HTTP = AuthorizedSession(google.auth.default()[0])
LOGGER = logging.getLogger('net-dash')
MONITORING_ROOT = 'netmon/'

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery(resources):
  '''Calls discovery plugin functions and collect discovered resources.

  The communication with discovery plugins uses double dispatch, where plugins
  accept either no args and return 1-n HTTP request instances, or a single HTTP
  response and return 1-n resource instances. A queue is set up for each plugin
  results since each call can return multiple requests or resources.

  Args:
    resources: pre-initialized map where discovered resources will be stored.
  '''
  LOGGER.info(f'discovery start')
  for plugin in plugins.get_discovery_plugins():
    # set up the queue with the initial list of HTTP requests from this plugin
    q = collections.deque(plugin.func(resources))
    while q:
      result = q.popleft()
      if isinstance(result, plugins.HTTPRequest):
        # fetch a single HTTP request
        response = fetch(result)
        if not response:
          continue
        if result.json:
          try:
            # decode the JSON HTTP response and pass it to the plugin
            results = plugin.func(resources, response, response.json())
          except json.decoder.JSONDecodeError as e:
            LOGGER.critical(
                f'error decoding JSON for {result.url}: {e.args[0]}')
            continue
        else:
          # pass the raw HTTP response to the plugin
          results = plugin.func(resources, response)
        q += collections.deque(results)
      elif isinstance(result, plugins.Resource):
        # store a resource the plugin derived from a previous HTTP response
        if result.key:
          # this specific resource is indexed by an additional key
          resources[result.type][result.id][result.key] = result.data
        else:
          resources[result.type][result.id] = result.data
  LOGGER.info('discovery end {}'.format(
      {k: len(v) for k, v in resources.items() if not isinstance(v, str)}))


def do_init(resources, organization, op_project, folders=None, projects=None,
            custom_quota=None):
  '''Calls init plugins to configure keys in the shared resource map.

  Args:
    organization: organization id from configuration.
    op_project: monitoring project id id from configuration.
    folders: list of folder ids for resource discovery from configuration.
    projects: list of project ids for resource discovery from configuration.
  '''
  LOGGER.info(f'init start')
  resources['config:organization'] = str(organization)
  resources['config:monitoring_project'] = op_project
  resources['config:folders'] = [str(f) for f in folders or []]
  resources['config:projects'] = projects or []
  resources['config:custom_quota'] = custom_quota or {}
  resources['config:monitoring_root'] = MONITORING_ROOT
  for plugin in plugins.get_init_plugins():
    plugin.func(resources)


def do_timeseries_calc(resources, descriptors, timeseries, debug_plugin=None):
  '''Calls timeseries plugins and collect resulting descriptors and timeseries.

  Timeseries plugin return a list of MetricDescriptors and Timeseries instances,
  one per each metric.

  Args:
    resources: shared map of configuration and discovered resources.
    descriptors: list where collected descriptors will be stored.
    timeseries: list where collected timeseries will be stored.
    debug_plugin: optional name of a single plugin to call
  '''
  LOGGER.info(f'timeseries calc start (debug plugin: {debug_plugin})')
  for plugin in plugins.get_timeseries_plugins():
    if debug_plugin and plugin.name != debug_plugin:
      LOGGER.info(f'skipping {plugin.name}')
      continue
    num_desc, num_ts = 0, 0
    for result in plugin.func(resources):
      if not result:
        continue
      # append result to the relevant collection (descriptors or timeseries)
      if isinstance(result, plugins.MetricDescriptor):
        descriptors.append(result)
        num_desc += 1
      elif isinstance(result, plugins.TimeSeries):
        timeseries.append(result)
        num_ts += 1
    LOGGER.info(f'{plugin.name}: {num_desc} descriptors {num_ts} timeseries')
  LOGGER.info('timeseries calc end (descriptors: {} timeseries: {})'.format(
      len(descriptors), len(timeseries)))


def do_timeseries_descriptors(project_id, existing, computed):
  '''Executes API calls for each previously computed metric descriptor.

  Args:
    project_id: monitoring project id where to write descriptors.
    existing: map of existing descriptor types.
    computed: list of plugins.MetricDescriptor instances previously computed.
  '''
  LOGGER.info('timeseries descriptors start')
  requests = plugins.monitoring.descriptor_requests(project_id, MONITORING_ROOT,
                                                    existing, computed)
  num = 0
  for request in requests:
    fetch(request)
    num += 1
  LOGGER.info('timeseries descriptors end (computed: {} created: {})'.format(
      len(computed), num))


def do_timeseries(project_id, timeseries, descriptors):
  '''Executes API calls for each previously computed timeseries.

  Args:
    project_id: monitoring project id where to write timeseries.
    timeseries: list of plugins.Timeseries instances.
    descriptors: list of plugins.MetricDescriptor instances matching timeseries.
  '''
  LOGGER.info('timeseries start')
  requests = plugins.monitoring.timeseries_requests(project_id, MONITORING_ROOT,
                                                    timeseries, descriptors)
  num = 0
  for request in requests:
    fetch(request)
    num += 1
  LOGGER.info('timeseries end (number: {} requests: {})'.format(
      len(timeseries), num))


def fetch(request):
  '''Minimal HTTP client interface for API calls.

  Executes the HTTP request passed as argument using the google.auth
  authenticated session.

  Args:
    request: an instance of plugins.HTTPRequest.
  Returns:
    JSON-decoded or raw response depending on the 'json' request attribute.
  '''
  # try
  LOGGER.debug(f'fetch {"POST" if request.data else "GET"} {request.url}')
  try:
    if not request.data:
      response = HTTP.get(request.url, headers=request.headers)
    else:
      response = HTTP.post(request.url, headers=request.headers,
                           data=request.data)
  except google.auth.exceptions.RefreshError as e:
    raise SystemExit(e.args[0])
  if response.status_code != 200:
    LOGGER.critical(
        f'response code {response.status_code} for URL {request.url}')
    LOGGER.critical(response.content)
    print(request.data)
    raise SystemExit(1)
  return response


@click.command()
@click.option('--organization', '-o', required=True, type=int,
              help='GCP organization id.')
@click.option('--op-project', '-op', required=True, type=str,
              help='GCP monitoring project where metrics will be stored.')
@click.option('--project', '-p', type=str, multiple=True,
              help='GCP project id, can be specified multiple times.')
@click.option('--folder', '-f', type=int, multiple=True,
              help='GCP folder id, can be specified multiple times.')
@click.option('--custom-quota-file', type=click.File('r'),
              help='Custom quota file in yaml format.')
@click.option('--dump-file', type=click.File('w'),
              help='Export JSON representation of resources to file.')
@click.option('--load-file', type=click.File('r'),
              help='Load JSON resources from file, skips init and discovery.')
@click.option('--debug-plugin',
              help='Run only core and specified timeseries plugin.')
def main(organization=None, op_project=None, project=None, folder=None,
         custom_quota_file=None, dump_file=None, load_file=None,
         debug_plugin=None):
  'CLI entry point.'
  logging.basicConfig(level=logging.INFO)
  descriptors = []
  timeseries = []
  if load_file:
    resources = json.load(load_file)
  else:
    custom_quota = {}
    resources = {}
    if custom_quota_file:
      try:
        custom_quota = yaml.load(custom_quota_file, Loader=yaml.Loader)
      except yaml.YAMLError as e:
        raise SystemExit(f'Error decoding custom quota file: {e.args[0]}')
    do_init(resources, organization, op_project, folder, project, custom_quota)
    do_discovery(resources)
    if dump_file:
      json.dump(resources, dump_file, indent=2)
  do_timeseries_calc(resources, descriptors, timeseries, debug_plugin)
  do_timeseries_descriptors(op_project, resources['metric-descriptors'],
                            descriptors)
  do_timeseries(op_project, timeseries, descriptors)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
