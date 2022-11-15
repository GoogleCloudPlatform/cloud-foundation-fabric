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
import requests

import plugins

from google.auth.transport.requests import AuthorizedSession

HTTP = AuthorizedSession(google.auth.default()[0])
Q_COLLECTION = collections.deque()
RESOURCES = {}

Resource = collections.namedtuple('Resource', 'id data')
Result = collections.namedtuple('Result', 'phase resource data')


def discovery_start():
  phase = plugins.Phase.DISCOVERY
  for plugin in plugins.get_plugins(phase, plugins.Step.START):
    for url in plugin.func(RESOURCES):
      data = fetch(url)
      Q_COLLECTION.append(Result(phase, plugin.resource, data))


def fetch(url):
  print(url)
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
  if organization:
    RESOURCES['organization'] = Resource(organization, {})
  if folder:
    RESOURCES['folders'] = [Resource(f, {}) for f in folder]
  if project:
    RESOURCES['project'] = [Resource(p, {}) for p in project]

  discovery_start()

  print(Q_COLLECTION)


if __name__ == '__main__':
  main(auto_envvar_prefix='NETMON')
