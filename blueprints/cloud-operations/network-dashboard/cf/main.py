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
Q_COLLECTION = collections.deque()
RESOURCES = {}

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery():
  LOGGER.info(f'discovery start')
  for plugin in plugins.get_discovery_plugins():
    q = collections.deque(plugin.func(RESOURCES))
    while q:
      result = q.popleft()
      if isinstance(result, plugins.HTTPRequest):
        response = fetch(result)
        if not response:
          continue
        if result.json:
          try:
            results = plugin.func(RESOURCES, response, response.json())
          except json.decoder.JSONDecodeError as e:
            LOGGER.critical(
                f'error decoding JSON for {result.url}: {e.args[0]}')
            continue
        else:
          results = plugin.func(RESOURCES, response)
        q += collections.deque(results)
      elif isinstance(result, plugins.Resource):
        if result.key:
          RESOURCES[result.type][result.id][result.key] = result.data
        else:
          RESOURCES[result.type][result.id] = result.data


def do_init(organization, folder, project, op_project):
  RESOURCES['organization'] = str(organization)
  RESOURCES['monitoring_project'] = op_project
  if folder:
    RESOURCES['folders'] = {f: {} for f in folder}
  if project:
    RESOURCES['projects'] = {p: {} for p in project}

  for plugin in plugins.get_init_plugins():
    plugin.func(RESOURCES)


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
def main(organization=None, op_project=None, project=None, folder=None):
  logging.basicConfig(level=logging.INFO)
  do_init(organization, folder, project, op_project)
  do_discovery()
  LOGGER.info(
      {k: len(v) for k, v in RESOURCES.items() if not isinstance(v, str)})

  # import icecream
  # icecream.ic(RESOURCES)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
