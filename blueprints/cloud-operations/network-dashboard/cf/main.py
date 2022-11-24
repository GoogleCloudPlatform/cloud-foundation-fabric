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

import collections
import json
import logging

import click
import google.auth
import plugins
import yaml

from google.auth.transport.requests import AuthorizedSession

HTTP = AuthorizedSession(google.auth.default()[0])
LOGGER = logging.getLogger('net-dash')

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery(resources):
  'Discover resources needed in measurements.'
  LOGGER.info(f'discovery start')
  for plugin in plugins.get_discovery_plugins():
    q = collections.deque(plugin.func(resources))
    while q:
      result = q.popleft()
      if isinstance(result, plugins.HTTPRequest):
        response = fetch(result)
        if not response:
          continue
        if result.json:
          try:
            results = plugin.func(resources, response, response.json())
          except json.decoder.JSONDecodeError as e:
            LOGGER.critical(
                f'error decoding JSON for {result.url}: {e.args[0]}')
            continue
        else:
          results = plugin.func(resources, response)
        q += collections.deque(results)
      elif isinstance(result, plugins.Resource):
        if result.key:
          resources[result.type][result.id][result.key] = result.data
        else:
          resources[result.type][result.id] = result.data


def do_init(resources, organization, op_project, folders=None, projects=None,
            custom_quota=None):
  'Prepare the resources datastructure fields.'
  LOGGER.info(f'init start')
  resources['config:organization'] = str(organization)
  resources['config:monitoring_project'] = op_project
  resources['config:folders'] = [str(f) for f in folders or []]
  resources['config:projects'] = projects or []
  resources['config:custom_quota'] = custom_quota or {}
  for plugin in plugins.get_init_plugins():
    plugin.func(resources)


def do_metric_descriptors(timeseries, op_project):
  'Create missing descriptors for custom metrics in timeseries.'
  pass


def do_timeseries(resources, descriptors, timeseries, debug_plugin=None):
  'Create timeseries.'
  LOGGER.info(f'timeseries start (debug plugin: {debug_plugin})')
  for plugin in plugins.get_timeseries_plugins():
    if debug_plugin and plugin.name != debug_plugin:
      LOGGER.info(f'skipping {plugin.name}')
      continue
    for result in plugin.func(resources):
      if not result:
        continue
      if isinstance(result, plugins.MetricDescriptor):
        descriptors[result.type] = result
      elif isinstance(result, plugins.TimeSeries):
        timeseries.append(result)


def fetch(request):
  'Minimal HTTP client interface for API calls.'
  # try
  LOGGER.info(f'fetch {request.url}')
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
    return
  return response


@click.command()
@click.option('--organization', '-o', required=True, type=int,
              help='GCP organization id')
@click.option('--op-project', '-op', required=True, type=str,
              help='GCP monitoring project where metrics will be stored')
@click.option('--project', '-p', type=str, multiple=True,
              help='GCP project id, can be specified multiple times')
@click.option('--folder', '-p', type=int, multiple=True,
              help='GCP folder id, can be specified multiple times')
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
  logging.basicConfig(level=logging.INFO)
  descriptors = {}
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
  do_timeseries(resources, descriptors, timeseries, debug_plugin)
  LOGGER.info(
      {k: len(v) for k, v in resources.items() if not isinstance(v, str)})
  LOGGER.info(f'{len(timeseries)} timeseries')

  if dump_file:
    json.dump(resources, dump_file, indent=2)

  import icecream
  icecream.ic(descriptors)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
