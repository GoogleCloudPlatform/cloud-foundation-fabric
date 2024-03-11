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
'Delete metric descriptors matching filter.'

import json
import logging

import click
import google.auth

from google.auth.transport.requests import AuthorizedSession

HEADERS = {'content-type': 'application/json'}
HTTP = AuthorizedSession(google.auth.default()[0])
URL_DELETE = 'https://monitoring.googleapis.com/v3/{}'
URL_LIST = (
    'https://monitoring.googleapis.com/v3/projects/{}'
    '/metricDescriptors?filter=metric.type=starts_with("custom.googleapis.com/netmon/")'
    '&alt=json')


def fetch(url, delete=False):
  'Minimal HTTP client interface for API calls.'
  # try
  try:
    if not delete:
      response = HTTP.get(url, headers=HEADERS)
    else:
      response = HTTP.delete(url)
  except google.auth.exceptions.RefreshError as e:
    raise SystemExit(e.args[0])
  if response.status_code != 200:
    logging.critical(f'response code {response.status_code} for URL {url}')
    logging.critical(response.content)
    return
  return response.json()


@click.command()
@click.option('--monitoring-project', '-op', required=True, type=str,
              help='GCP monitoring project where metrics will be stored.')
def main(monitoring_project):
  'Module entry point.'
  # if not click.confirm('Do you want to continue?'):
  #   raise SystemExit(0)
  logging.info('fetching descriptors')
  result = fetch(URL_LIST.format(monitoring_project))
  descriptors = result.get('metricDescriptors')
  if not descriptors:
    raise SystemExit(0)
  logging.info(f'{len(descriptors)} descriptors')
  for d in descriptors:
    name = d['name']
    logging.info(f'delete {name}')
    result = fetch(URL_DELETE.format(name), True)


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  main()
