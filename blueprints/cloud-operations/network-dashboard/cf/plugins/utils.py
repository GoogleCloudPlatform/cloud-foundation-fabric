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

import logging
import re

RE_URL = re.compile(r'pageToken=[^&]+&?')


def parse_cai_results(data, name, resource_type=None, method='search'):
  results = data.get('results' if method == 'search' else 'assets')
  if not results:
    logging.info(f'no results for {name}')
    return
  for result in results:
    if resource_type and result['assetType'] != resource_type:
      logging.warn(f'result for wrong type {result["assetType"]}')
      continue
    yield result


def parse_cai_page_token(data, url):
  page_token = data.get('pageToken')
  if page_token:
    return RE_URL.sub(f'pageToken={page_token}&', url)
