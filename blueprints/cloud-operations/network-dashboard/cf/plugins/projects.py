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

from . import register, Level, Phase, Step

LEVEL = Level.CORE
NAME = 'project'
TYPE = 'cloudresourcemanager.googleapis.com/Project'

_CAI_URL = ('https://content-cloudasset.googleapis.com/v1p1beta1/folders'
            '/{}/resources:searchAll'
            '?assetTypes=cloudresourcemanager.googleapis.com%2FProject')


@register(NAME, Phase.DISCOVERY, Step.START, LEVEL, 0)
def start_discovery(resources):
  for f in resources.get('folders', []):
    yield _CAI_URL.format(f.id)


@register(NAME, Phase.DISCOVERY, Step.END, LEVEL, 0)
def end_discovery(resources, data):
  return


@register(NAME, Phase.COLLECTION, Step.START, LEVEL, 0)
def start_collection(resources):
  return


@register(NAME, Phase.COLLECTION, Step.END, LEVEL, 0)
def end_collection(resources, metrics, data):
  return
