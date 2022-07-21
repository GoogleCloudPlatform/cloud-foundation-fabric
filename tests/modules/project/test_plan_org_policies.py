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

def test_policy_boolean(plan_runner):
  "Test boolean org policy."
  policy_boolean = '{policy-a = true, policy-b = false, policy-c = null}'
  _, resources = plan_runner(policy_boolean=policy_boolean)
  assert len(resources) == 7
  resources = [r for r in resources if r['type']
               == 'google_project_organization_policy']
  assert sorted([r['index'] for r in resources]) == [
      'policy-a', 'policy-b', 'policy-c'
  ]
  policy_values = []
  for resource in resources:
    for policy in ('boolean_policy', 'restore_policy'):
      value = resource['values'][policy]
      if value:
        policy_values.append((policy,) + value[0].popitem())
  assert sorted(policy_values) == [
      ('boolean_policy', 'enforced', False),
      ('boolean_policy', 'enforced', True),
      ('restore_policy', 'default', True)
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
  _, resources = plan_runner(policy_list=policy_list)
  assert len(resources) == 7
  values = [r['values'] for r in resources if r['type']
            == 'google_project_organization_policy']
  assert [r['constraint'] for r in values] == [
      'policy-a', 'policy-b', 'policy-c'
  ]
  assert values[0]['list_policy'][0]['allow'] == [
      {'all': True, 'values': None}]
  assert values[1]['list_policy'][0]['deny'] == [
      {'all': False, 'values': ["bar"]}]
  assert values[2]['restore_policy'] == [{'default': True}]
