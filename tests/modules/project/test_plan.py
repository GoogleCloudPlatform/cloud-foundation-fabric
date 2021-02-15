# Copyright 2021 Google LLC
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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_prefix(plan_runner):
  "Test project id prefix."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert resources[0]['values']['name'] == 'my-project'
  _, resources = plan_runner(FIXTURES_DIR, prefix='foo')
  assert len(resources) == 1
  assert resources[0]['values']['name'] == 'foo-my-project'


def test_parent(plan_runner):
  "Test project parent."
  _, resources = plan_runner(FIXTURES_DIR, parent='folders/12345678')
  assert len(resources) == 1
  assert resources[0]['values']['folder_id'] == '12345678'
  assert resources[0]['values'].get('org_id') == None
  _, resources = plan_runner(FIXTURES_DIR, parent='organizations/12345678')
  assert len(resources) == 1
  assert resources[0]['values']['org_id'] == '12345678'
  assert resources[0]['values'].get('folder_id') == None


def test_no_parent(plan_runner):
  "Test null project parent."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert resources[0]['values'].get('folder_id') == None
  assert resources[0]['values'].get('org_id') == None
