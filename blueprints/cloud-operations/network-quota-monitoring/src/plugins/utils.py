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
'Utility functions for API requests and responses.'

import itertools
import json
import logging
import re

from . import HTTPRequest, PluginError

MP_PART = '''\
Content-Type: application/http
MIME-Version: 1.0
Content-Transfer-Encoding: binary

GET {}?alt=json HTTP/1.1
Content-Type: application/json
MIME-Version: 1.0
Content-Length: 0
Accept: application/json
Accept-Encoding: gzip, deflate
Host: compute.googleapis.com

'''
RE_URL = re.compile(r'nextPageToken=[^&]+&?')


def batched(iterable, n):
  'Batches data into lists of length n. The last batch may be shorter.'
  # batched('ABCDEFG', 3) --> ABC DEF G
  if n < 1:
    raise ValueError('n must be at least one')
  it = iter(iterable)
  while (batch := list(itertools.islice(it, n))):
    yield batch


def parse_cai_results(data, name, resource_type=None, method='search'):
  'Parses an asset API response and returns individual results.'
  results = data.get('results' if method == 'search' else 'assets')
  if not results:
    logging.info(f'no results for {name}')
    return
  for result in results:
    if resource_type and result['assetType'] != resource_type:
      logging.warn(f'result for wrong type {result["assetType"]}')
      continue
    yield result


def parse_page_token(data, url):
  'Detect next page token in result and return next page URL.'
  page_token = data.get('nextPageToken')
  if page_token:
    logging.info(f'page  token {page_token}')
  if page_token:
    return RE_URL.sub(f'pageToken={page_token}&', url)


def poor_man_mp_request(urls, boundary='1234567890'):
  'Bundles URLs into a single multipart mixed batched request.'
  boundary = f'--{boundary}'
  data = [boundary]
  for url in urls:
    data += ['\n', MP_PART.format(url), boundary]
  data.append('--\n')
  headers = {'content-type': f'multipart/mixed; boundary={boundary[2:]}'}
  return HTTPRequest('https://compute.googleapis.com/batch/compute/v1', headers,
                     ''.join(data), False)


def poor_man_mp_response(content_type, content):
  'Parses a multipart mixed response and returns individual parts.'
  try:
    _, boundary = content_type.split('=')
  except ValueError:
    raise PluginError('no boundary found in content type')
  content = content.decode('utf-8').strip()[:-2]
  if boundary not in content:
    raise PluginError('MIME boundary not found')
  for part in content.split(f'--{boundary}'):
    part = part.strip()
    if not part:
      continue
    try:
      mime_header, header, body = part.split('\r\n\r\n', 3)
    except ValueError:
      raise PluginError('cannot parse MIME part')
    yield json.loads(body)
