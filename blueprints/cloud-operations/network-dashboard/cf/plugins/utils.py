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


def parse_cai_results(resource_name, resource_type, data):
  results = data.get('results')
  if not results:
    logging.info(f'no results for {resource_name}')
    return
  for result in results:
    if result['assetType'] != resource_type:
      logging.warn(f'result for wrong type {result["assetType"]}')
      continue
    yield result


def parse_cai_page_token(url, data):
  page_token = data.get('pageToken')
  if page_token:
    url, _, _ = url.split('&pageToken')[0]
    return f'{url}&pageToken={page_token}'
