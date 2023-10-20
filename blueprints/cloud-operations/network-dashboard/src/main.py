#!/usr/bin/env python3
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
'Network dashboard: create network-related metric timeseries for GCP resources.'

import base64
import binascii
import collections
import json
import logging
import os

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
            LOGGER.debug(f'passing JSON result to {plugin.name}')
            results = plugin.func(resources, response, response.json())
          except json.decoder.JSONDecodeError as e:
            LOGGER.critical(
                f'error decoding JSON for {result.url}: {e.args[0]}')
            continue
        else:
          # pass the raw HTTP response to the plugin
          LOGGER.debug(f'passing raw result to {plugin.name}')
          results = plugin.func(resources, response)
        q += collections.deque(results)
      elif isinstance(result, plugins.Resource):
        # store a resource the plugin derived from a previous HTTP response
        LOGGER.debug(f'got resource {result} from {plugin.name}')
        if result.key:
          # this specific resource is indexed by an additional key
          resources[result.type][result.id][result.key] = result.data
        else:
          resources[result.type][result.id] = result.data
  LOGGER.info('discovery end {}'.format({
      k: len(v) for k, v in resources.items() if not isinstance(v, str)
  }))


def do_init(resources, discovery_root, monitoring_project, folders=None,
            projects=None, custom_quota=None):
  '''Calls init plugins to configure keys in the shared resource map.

  Args:
    discovery_root: root node for discovery from configuration.
    monitoring_project: monitoring project id id from configuration.
    folders: list of folder ids for resource discovery from configuration.
    projects: list of project ids for resource discovery from configuration.
  '''
  LOGGER.info(f'init start')
  folders = [str(f) for f in folders or []]
  resources['config:discovery_root'] = discovery_root
  resources['config:monitoring_project'] = monitoring_project
  resources['config:folders'] = folders
  resources['config:projects'] = projects or []
  resources['config:custom_quota'] = custom_quota or {}
  resources['config:monitoring_root'] = MONITORING_ROOT
  if discovery_root.startswith('organization'):
    resources['organization'] = discovery_root.split('/')[-1]
  for f in folders:
    resources['folders'] = {f: {} for f in folders}
  for plugin in plugins.get_init_plugins():
    plugin.func(resources)
  LOGGER.info(f'init completed, resources {resources}')


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


def main_cf_pubsub(event, context):
  'Entry point for Cloud Function triggered by a PubSub message.'
  debug = os.environ.get('DEBUG')
  logging.basicConfig(level=logging.DEBUG if debug else logging.INFO)
  LOGGER.info('processing pubsub payload')
  try:
    payload = json.loads(base64.b64decode(event['data']).decode('utf-8'))
  except (binascii.Error, json.JSONDecodeError) as e:
    raise SystemExit(f'Invalid payload: e.args[0].')
  discovery_root = payload.get('discovery_root')
  monitoring_project = payload.get('monitoring_project')
  if not discovery_root:
    LOGGER.critical('no discovery roo project specified')
    LOGGER.info(payload)
    raise SystemExit(f'Invalid options')
  if not monitoring_project:
    LOGGER.critical('no monitoring project specified')
    LOGGER.info(payload)
    raise SystemExit(f'Invalid options')
  if discovery_root.partition('/')[0] not in ('folders', 'organizations'):
    raise SystemExit(f'Invalid discovery root {discovery_root}.')
  custom_quota = payload.get('custom_quota', {})
  descriptors = []
  folders = payload.get('folders', [])
  projects = payload.get('projects', [])
  resources = {}
  timeseries = []
  do_init(resources, discovery_root, monitoring_project, folders, projects,
          custom_quota)
  do_discovery(resources)
  do_timeseries_calc(resources, descriptors, timeseries)
  do_timeseries_descriptors(monitoring_project, resources['metric-descriptors'],
                            descriptors)
  do_timeseries(monitoring_project, timeseries, descriptors)


@click.command()
@click.option(
    '--discovery-root', '-dr', required=True,
    help='Root node for asset discovery, organizations/nnn or folders/nnn.')
@click.option('--monitoring-project', '-mon', required=True, type=str,
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
@click.option('--debug', is_flag=True, default=False,
              help='Turn on debug logging.')
def main(discovery_root, monitoring_project, project=None, folder=None,
         custom_quota_file=None, dump_file=None, load_file=None,
         debug_plugin=None, debug=False):
  'CLI entry point.'
  logging.basicConfig(level=logging.INFO if not debug else logging.DEBUG)
  if discovery_root.partition('/')[0] not in ('folders', 'organizations'):
    raise SystemExit('Invalid discovery root.')
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
    do_init(resources, discovery_root, monitoring_project, folder, project,
            custom_quota)
    do_discovery(resources)
    if dump_file:
      json.dump(resources, dump_file, indent=2)
  do_timeseries_calc(resources, descriptors, timeseries, debug_plugin)
  do_timeseries_descriptors(monitoring_project, resources['metric-descriptors'],
                            descriptors)
  do_timeseries(monitoring_project, timeseries, descriptors)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
