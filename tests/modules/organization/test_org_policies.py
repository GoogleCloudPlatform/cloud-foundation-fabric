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
  tfvars = 'test.orgpolicies-boolean.tfvars'
  _, resources = plan_runner(extra_files=[tfvars], tf_var_file=tfvars)
  validate_policy_boolean_resources(resources)


def validate_policy_boolean_resources(resources):
  assert len(resources) == 2
  assert all(
      r['values']['parent'] == 'organizations/1234567890' for r in resources)
  policies = {
      r['index']: r['values']['spec'][0]
      for r in resources
      if r['type'] == 'google_org_policy_policy'
  }
  assert len(policies) == 2
  import icecream
  icecream.ic(policies)
  p1 = policies['iam.disableServiceAccountKeyCreation']
  assert p1['inherit_from_parent'] is None
  assert p1['reset'] is None
  assert p1['rules'] == [{
      'allow_all': None,
      'condition': [],
      'deny_all': None,
      'enforce': 'TRUE',
      'values': []
  }]
  p2 = policies['iam.disableServiceAccountKeyUpload']
  assert p2['inherit_from_parent'] is None
  assert p2['reset'] is None
  assert len(p2['rules']) == 2
  assert p2['rules'][0] == {
      'allow_all': None,
      'condition': [],
      'deny_all': None,
      'enforce': 'FALSE',
      'values': []
  }
  assert p2['rules'][1] == {
      'allow_all': None,
      'condition': [{
          'description': 'test condition',
          'expression': 'resource.matchTagId(aa, bb)',
          'location': 'xxx',
          'title': 'condition'
      }],
      'deny_all': None,
      'enforce': 'TRUE',
      'values': []
  }
