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

from google.auth.transport.requests import AuthorizedSession

try:
  HTTP = AuthorizedSession(google.auth.default()[0])
except google.auth.exceptions.RefreshError as e:
  raise SystemExit(e.args[0])
LOGGER = logging.getLogger('net-dash')

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery(resources):
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


def do_init(resources, organization, op_project, folders=None, projects=None):
  LOGGER.info(f'init start')
  resources['config:organization'] = str(organization)
  resources['config:monitoring_project'] = op_project
  resources['config:folders'] = [str(f) for f in folders or []]
  resources['config:projects'] = projects or []
  for plugin in plugins.get_init_plugins():
    plugin.func(resources)


def do_timeseries(resources, timeseries):
  LOGGER.info(f'timeseries start')
  for plugin in plugins.get_timeseries_plugins():
    for result in plugin.func(resources):
      if not result:
        continue
      timeseries.append(result)


def fetch(request):
  # try
  LOGGER.info(f'fetch {request.url}')
  if not request.data:
    response = HTTP.get(request.url, headers=request.headers)
  else:
    response = HTTP.post(request.url, headers=request.headers,
                         data=request.data)
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
@click.option('--dump-file', type=click.File('w'),
              help='Export JSON representation of resources to file.')
@click.option('--load-file', type=click.File('r'),
              help='Load JSON resources from file, skips init and discovery.')
def main(organization=None, op_project=None, project=None, folder=None,
         dump_file=None, load_file=None):
  logging.basicConfig(level=logging.INFO)
  timeseries = []
  if load_file:
    resources = json.load(load_file)
  else:
    resources = {}
    do_init(resources, organization, op_project, folder, project)
    do_discovery(resources)
  do_timeseries(resources, timeseries)
  LOGGER.info(
      {k: len(v) for k, v in resources.items() if not isinstance(v, str)})
  LOGGER.info(f'{len(timeseries)} timeseries')

  if dump_file:
    json.dump(resources, dump_file, indent=2)

  # from icecream import ic
  # ic(timeseries)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
