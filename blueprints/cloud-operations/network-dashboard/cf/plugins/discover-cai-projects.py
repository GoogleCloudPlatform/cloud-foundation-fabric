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

import json
import logging

from . import HTTPRequest, Level, register_init, register_discovery
from .utils import parse_cai_page_token, parse_cai_results

NAME = 'projects'
TYPE = 'cloudresourcemanager.googleapis.com/Project'

CAI_URL = (
    'https://content-cloudasset.googleapis.com/v1p1beta1'
    '/{}/resources:searchAll'
    f'?assetTypes=cloudresourcemanager.googleapis.com%2FProject&pageSize=500')


def _handle_discovery(resources, response):
  request = response.request
  try:
    data = response.json()
  except json.decoder.JSONDecodeError as e:
    logging.critical(f'error decoding URL {request.url}: {e.args[0]}')
    return {}
  for result in parse_cai_results(data, NAME, TYPE):
    number = result['project'].split('/')[1]
    project_id = result['displayName']
    resources[NAME][project_id] = {'number': number}
    resources['projects:number'][number] = project_id
  next_url = parse_cai_page_token(data, request.url)
  if next_url:
    yield HTTPRequest(next_url, {}, None)


@register_init()
def init(resources):
  if NAME not in resources:
    resources[NAME] = {}
  if 'project:numbers' not in resources:
    resources['projects:number'] = {}


@register_discovery(_handle_discovery, Level.CORE, 0)
def start_discovery(resources):
  logging.info('discovery projects start')
  for resource_type in (NAME, 'folders'):
    for k in resources.get(resource_type, []):
      yield HTTPRequest(CAI_URL.format(f'{resource_type}/{k}'), {}, None)
