# Copyright 2020 Google LLC
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


def test_policy_boolean(plan_runner):
  "Test boolean folder policy."
  policy_boolean = '{policy-a = true, policy-b = false, policy-c = null}'
  _, resources = plan_runner(FIXTURES_DIR, policy_boolean=policy_boolean)
  assert len(resources) == 8
  resources = [r for r in resources if r['type']
               == 'google_folder_organization_policy']
  assert sorted([r['index'] for r in resources]) == [
      'folder-a-policy-a',
      'folder-a-policy-b',
      'folder-a-policy-c',
      'folder-b-policy-a',
      'folder-b-policy-b',
      'folder-b-policy-c'
  ]
  policy_values = []
  for resource in resources:
    for policy in ('boolean_policy', 'restore_policy'):
      value = resource['values'][policy]
      if value:
        policy_values.append((resource['index'], policy,) + value[0].popitem())
  assert sorted(policy_values) == [
      ('folder-a-policy-a', 'boolean_policy', 'enforced', True),
      ('folder-a-policy-b', 'boolean_policy', 'enforced', False),
      ('folder-a-policy-c', 'restore_policy', 'default', True),
      ('folder-b-policy-a', 'boolean_policy', 'enforced', True),
      ('folder-b-policy-b', 'boolean_policy', 'enforced', False),
      ('folder-b-policy-c', 'restore_policy', 'default', True)
  ]


def test_policy_list(plan_runner):
  "Test list org policy."
  policy_list = (
      '{'
      'policy-a = {inherit_from_parent = true, suggested_value = null, status = true, values = []}, '
      'policy-b = {inherit_from_parent = null, suggested_value = "foo", status = false, values = ["bar"]}, '
      'policy-c = {inherit_from_parent = null, suggested_value = true, status = null, values = null}'
      '}'
  )
  _, resources = plan_runner(FIXTURES_DIR, policy_list=policy_list)
  assert len(resources) == 8
  resources = [r for r in resources if r['type']
               == 'google_folder_organization_policy']
  assert sorted([r['index'] for r in resources]) == [
      'folder-a-policy-a',
      'folder-a-policy-b',
      'folder-a-policy-c',
      'folder-b-policy-a',
      'folder-b-policy-b',
      'folder-b-policy-c'
  ]
  values = [r['values'] for r in resources]
  assert [r['constraint'] for r in values] == [
      'policy-a', 'policy-b', 'policy-c', 'policy-a', 'policy-b', 'policy-c'
  ]
  for i in (0, 3):
    assert values[i]['list_policy'][0]['allow'] == [
        {'all': True, 'values': None}]
  for i in (1, 4):
    assert values[i]['list_policy'][0]['deny'] == [
        {'all': False, 'values': ["bar"]}]
  for i in (2, 5):
    assert values[i]['restore_policy'] == [{'default': True}]
