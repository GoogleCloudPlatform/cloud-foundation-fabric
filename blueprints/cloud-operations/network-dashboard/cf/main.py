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

HTTP = AuthorizedSession(google.auth.default()[0])
Q_COLLECTION = collections.deque()
RESOURCES = {}

Result = collections.namedtuple('Result', 'phase resource data')


def do_discovery():
  phase = plugins.Phase.DISCOVER
  data_handlers = {
      p.resource: p.func for p in plugins.get_plugins(phase, plugins.Step.END)
  }
  for plugin in plugins.get_plugins(phase, plugins.Step.START):
    logging.info(f'discovery {plugin.resource}')
    data_handler = data_handlers.get(plugin.resource)
    requests = collections.deque(plugin.func(RESOURCES))
    while requests:
      request = requests.popleft()
      response = fetch(request)
      if not data_handler:
        logging.warn(f'no discovery data handler for {plugin.resource}')
      for next_request in data_handler(RESOURCES, response):
        if not next_request:
          continue
        logging.info(f'next request {next_request}')
        requests.append(next_request)


def do_init(organization, folder, project):
  if organization:
    RESOURCES['organization'] = {'id': organization}
  if folder:
    RESOURCES['folders'] = {f: {} for f in folder}
  if project:
    RESOURCES['projects'] = {p: {} for p in project}
  phase = plugins.Phase.INIT
  for plugin in plugins.get_plugins(phase):
    plugin.func(RESOURCES)


def fetch(request):
  # try
  logging.info(f'fetch {request.url}')
  if not request.data:
    response = HTTP.get(request.url, headers=request.headers)
  else:
    response = HTTP.post(request.url, headers=request.headers,
                         data=request.data)
  if response.status_code != 200:
    # TODO: handle this
    logging.critical(
        f'response code {response.status_code} for URL {request.url}')
    print(request.url)
    print(request.headers)
    print(request.data)
    print(response.headers)
    print(response.content)
  return response


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

  do_discovery()

  import icecream
  icecream.ic(RESOURCES)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
