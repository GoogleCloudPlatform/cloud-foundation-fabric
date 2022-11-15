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

import click
import collections
import google.auth
import logging
import requests

import plugins

from google.auth.transport.requests import AuthorizedSession

HTTP = AuthorizedSession(google.auth.default()[0])
Q_COLLECTION = collections.deque()
RESOURCES = {}

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery_end():
  phase, step = plugins.Phase.DISCOVERY, plugins.Step.END
  handlers = {p.resource: p.func for p in plugins.get_plugins(phase, step)}
  while Q_COLLECTION:
    result = Q_COLLECTION.popleft()
    func = handlers.get(result.resource)
    if not func:
      logging.critical(
          f'collection result with no handler for {result.resource}')
      print(result.resource, result.data)
    else:
      func(RESOURCES, result.data)


def do_discovery_start():
  phase, step = plugins.Phase.DISCOVERY, plugins.Step.START
  for plugin in plugins.get_plugins(phase, step):
    for url in plugin.func(RESOURCES):
      data = fetch(url)
      Q_COLLECTION.append(Result(phase, plugin.resource, data))


def do_init(organization, folder, project):
  if organization:
    RESOURCES['organization'] = {organization: {}}
  if folder:
    RESOURCES['folders'] = {f: {} for f in folder}
  if project:
    RESOURCES['projects'] = {p: {} for p in project}
  phase = plugins.Phase.INIT
  for plugin in plugins.get_plugins(phase):
    plugin.func(RESOURCES)


def fetch(url):
  # try
  response = HTTP.get(url)
  return response.json()


@click.command()
@click.option('--organization', '-o', required=True, type=int,
              help='GCP organization id')
@click.option('--op-project', '-op', required=True, type=str,
              help='GCP monitoring project where metrics will be stored')
@click.option('--project', '-p', required=False, type=str, multiple=True,
              help='GCP project id, can be specified multiple times')
@click.option('--folder', '-p', required=False, type=int, multiple=True,
              help='GCP folder id, can be specified multiple times')
def main(organization=None, op_project=None, project=None, folder=None):
  logging.basicConfig(level=logging.INFO)

  do_init(organization, folder, project)

  do_discovery_start()

  do_discovery_end()

  import icecream
  icecream.ic(RESOURCES)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
