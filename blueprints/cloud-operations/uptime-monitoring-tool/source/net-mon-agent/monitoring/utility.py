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

import collections
import google.auth
import itertools
import json
import requests.exceptions
import logging
from google.auth.transport.requests import AuthorizedSession

HTTP = AuthorizedSession(google.auth.default()[0])
HTTP_HEADERS = {'content-type': 'application/json; charset=UTF-8'}
URL_PROJECT = 'https://compute.googleapis.com/compute/v1/projects/{}'
URL_REGION = 'https://compute.googleapis.com/compute/v1/projects/{}/regions/{}'
URL_TS = 'https://monitoring.googleapis.com/v3/projects/{}/timeSeries'

LOGGER = logging.getLogger('utility')

HTTPRequest = collections.namedtuple(
    'HTTPRequest', 'url data headers', defaults=[{}, {
        'content-type': 'application/json; charset=UTF-8'
    }])


class NotFound(Exception):
  pass


def batched(iterable, n):
  'Batches data into lists of length n. The last batch may be shorter.'
  # batched('ABCDEFG', 3) --> ABC DEF G
  if n < 1:
    raise ValueError('n must be at least one')
  it = iter(iterable)
  while (batch := list(itertools.islice(it, n))):
    yield batch


def fetch(request, delete=False):
  'Minimal HTTP client interface for API calls.'
  logging.debug(f'fetch {"POST" if request.data else "GET"} {request.url}')
  logging.debug(request.data)
  try:
    if delete:
      response = HTTP.delete(request.url, headers=request.headers)
    elif not request.data:
      response = HTTP.get(request.url, headers=request.headers)
    else:
      response = HTTP.post(request.url, headers=request.headers,
                           data=json.dumps(request.data))
  except (google.auth.exceptions.RefreshError,
          requests.exceptions.ReadTimeout) as e:
    raise SystemExit(e.args[0])
  try:
    rdata = json.loads(response.content)
  except json.JSONDecodeError as e:
    logging.critical(e)
    raise SystemExit(f'Error decoding response: {response.content}')
  if response.status_code == 404:
    raise NotFound(
        f'Resource not found. Error: {rdata.get("error")} URL: {request.url}')
  if response.status_code != 200:
    logging.critical(rdata)
    error = rdata.get('error', {})
    raise SystemExit('API error: {} (HTTP {})'.format(
        error.get('message', 'error message cannot be decoded'),
        error.get('code', 'no code found')))
  return json.loads(response.content)


def write_timeseries(project, data):
  'Sends timeseries to the API.'
  # try
  logging.debug(f'write {len(data["timeSeries"])} timeseries')
  request = HTTPRequest(URL_TS.format(project), data)
  return fetch(request)
