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

from . import *

LEVEL = Level.CORE
NAME = 'project'
TYPE = 'cloudresourcemanager.googleapis.com/Project'

CAI_URL = ('https://content-cloudasset.googleapis.com/v1p1beta1'
           '/{}/resources:searchAll'
           '?assetTypes=cloudresourcemanager.googleapis.com%2FProject')


@register(NAME, Phase.INIT, Step.START)
def start_discovery(resources):
  if 'projects' not in resources:
    resources['projects'] = []


@register(NAME, Phase.DISCOVERY, Step.START, LEVEL, 0)
def start_discovery(resources):
  for resource_type in ('projects', 'folders'):
    for k in resources.get(resource_type, []):
      yield CAI_URL.format(f'{resource_type}/{k}')


@register(NAME, Phase.DISCOVERY, Step.END)
def end_discovery(resources, data):
  results = data.get('results')
  if not results:
    raise PluginError('---')
  for result in results:
    if result['assetType'] != TYPE:
      logging.warn(f'result for wrong type {result["assetType"]}')
      continue
    number = result['project'].split('/')[1]
    project_id = result['displayName']
    resources['projects'][project_id] = {'number': number}


@register(NAME, Phase.COLLECTION, Step.START, LEVEL, 0)
def start_collection(resources):
  return


@register(NAME, Phase.COLLECTION, Step.END)
def end_collection(resources, metrics, data):
  return
