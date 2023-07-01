#!/usr/bin/env python
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
'Manages metric descriptors for the DR metrics.'

import collections
import json
import logging
import urllib.parse

import click
import google.auth

from google.auth.transport.requests import AuthorizedSession

Descriptor = collections.namedtuple('Descriptor', 'name labels is_bool r_type',
                                    defaults=[True, 'global'])
HTTPRequest = collections.namedtuple(
    'HTTPRequest', 'url data headers', defaults=[{}, {
        'content-type': 'application/json; charset=UTF-8'
    }])


class Error(Exception):
  pass


BASE = 'custom.googleapis.com/quota'
HTTP = AuthorizedSession(google.auth.default()[0])


def descriptors_get(project):
  base = urllib.parse.quote_plus(BASE)
  url = (f'https://content-monitoring.googleapis.com/v3/projects/{project}/'
         'metricDescriptors?filter=metric.type%20%3D%20starts_with'
         f'(%22{base}%22)')
  return HTTPRequest(url)


def descriptor_delete(project, type):
  url = (f'https://monitoring.googleapis.com/v3/projects/{project}/'
         f'metricDescriptors/{type}')
  return HTTPRequest(url)


def fetch(request, delete=False):
  'Minimal HTTP client interface for API calls.'
  # try
  logging.debug(f'fetch {"POST" if request.data else "GET"} {request.url}')
  try:
    if delete:
      response = HTTP.delete(request.url, headers=request.headers)
    elif not request.data:
      response = HTTP.get(request.url, headers=request.headers)
    else:
      response = HTTP.post(request.url, headers=request.headers,
                           data=json.dumps(request.data))
  except google.auth.exceptions.RefreshError as e:
    raise SystemExit(e.args[0])
  if response.status_code != 200:
    logging.critical(
        f'response code {response.status_code} for URL {request.url}')
    logging.critical(response.content)
    logging.debug(request.data)
    raise Error('API error')
  return json.loads(response.content)


@click.command()
@click.argument('project')
@click.option('--delete', default=False, is_flag=True,
              help='Delete descriptors.')
@click.option('--dry-run', default=False, is_flag=True,
              help='Show but to not perform actions.')
def main(project, delete=False, dry_run=False):
  'Program entry point.'
  logging.basicConfig(level=logging.INFO)
  logging.info(f'getting descriptors for "{BASE}"')
  response = fetch(descriptors_get(project))
  existing = [d['type'] for d in response.get('metricDescriptors', [])]
  logging.info(f'{len(existing)} descriptors')
  if delete:
    for name in existing:
      logging.info(f'deleting descriptor {name}')
      if not dry_run:
        try:
          fetch(descriptor_delete(project, name), delete=True)
        except Error:
          logging.critical(f'error deleting descriptor {name}')


if __name__ == '__main__':
  main()