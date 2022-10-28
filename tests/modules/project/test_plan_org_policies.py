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
  policies = '''{
    "iam.disableServiceAccountKeyCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyUpload" = {
      enforce = false
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId(\\"tagKeys/1234\\", \\"tagValues/1234\\")"
            title       = "condition"
            description = "test condition"
            location    = "xxx"
          }
          enforce = true
        }
      ]
    }
  }'''
  _, resources = plan_runner(org_policies=policies)
  assert len(resources) == 6

  policies = [r for r in resources if r['type'] == 'google_org_policy_policy']
  assert len(policies) == 2
  assert all(x['values']['parent'] == 'projects/my-project' for x in policies)

  p1 = [
      r['values']['spec'][0]
      for r in policies
      if r['index'] == 'iam.disableServiceAccountKeyCreation'
  ][0]

  assert p1['inherit_from_parent'] is None
  assert p1['reset'] is None
  assert p1['rules'] == [{
      'allow_all': None,
      'condition': [],
      'deny_all': None,
      'enforce': 'TRUE',
      'values': []
  }]

  p2 = [
      r['values']['spec'][0]
      for r in policies
      if r['index'] == 'iam.disableServiceAccountKeyUpload'
  ][0]

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
          'expression': 'resource.matchTagId("tagKeys/1234", "tagValues/1234")',
          'location': 'xxx',
          'title': 'condition'
      }],
      'deny_all': None,
      'enforce': 'TRUE',
      'values': []
  }


def test_policy_list(plan_runner):
  "Test list org policy."
  policies = '''{
    "compute.vmExternalIpAccess" = {
      deny = { all = true }
    }
    "iam.allowedPolicyMemberDomains" = {
      allow = {
        values = ["C0xxxxxxx", "C0yyyyyyy"]
      }
    }
    "compute.restrictLoadBalancerCreationForTypes" = {
      deny = { values = ["in:EXTERNAL"] }
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId(\\"tagKeys/1234\\", \\"tagValues/1234\\")"
            title       = "condition"
            description = "test condition"
            location    = "xxx"
          }
          allow = {
            values = ["EXTERNAL_1"]
          }
        },
        {
          condition = {
            expression  = "resource.matchTagId(\\"tagKeys/12345\\", \\"tagValues/12345\\")"
            title       = "condition2"
            description = "test condition2"
            location    = "xxx"
          }
          allow = {
            all = true
          }
        }
      ]
    }
  }'''
  _, resources = plan_runner(org_policies=policies)
  assert len(resources) == 7

  policies = [r for r in resources if r['type'] == 'google_org_policy_policy']
  assert len(policies) == 3
  assert all(x['values']['parent'] == 'projects/my-project' for x in policies)

  p1 = [
      r['values']['spec'][0]
      for r in policies
      if r['index'] == 'compute.vmExternalIpAccess'
  ][0]
  assert p1['inherit_from_parent'] is None
  assert p1['reset'] is None
  assert p1['rules'] == [{
      'allow_all': None,
      'condition': [],
      'deny_all': 'TRUE',
      'enforce': None,
      'values': []
  }]

  p2 = [
      r['values']['spec'][0]
      for r in policies
      if r['index'] == 'iam.allowedPolicyMemberDomains'
  ][0]
  assert p2['inherit_from_parent'] is None
  assert p2['reset'] is None
  assert p2['rules'] == [{
      'allow_all':
          None,
      'condition': [],
      'deny_all':
          None,
      'enforce':
          None,
      'values': [{
          'allowed_values': [
              'C0xxxxxxx',
              'C0yyyyyyy',
          ],
          'denied_values': None
      }]
  }]

  p3 = [
      r['values']['spec'][0]
      for r in policies
      if r['index'] == 'compute.restrictLoadBalancerCreationForTypes'
  ][0]
  assert p3['inherit_from_parent'] is None
  assert p3['reset'] is None
  assert len(p3['rules']) == 3
  assert p3['rules'][0] == {
      'allow_all': None,
      'condition': [],
      'deny_all': None,
      'enforce': None,
      'values': [{
          'allowed_values': None,
          'denied_values': ['in:EXTERNAL']
      }]
  }

  assert p3['rules'][1] == {
      'allow_all': None,
      'condition': [{
          'description': 'test condition',
          'expression': 'resource.matchTagId("tagKeys/1234", "tagValues/1234")',
          'location': 'xxx',
          'title': 'condition'
      }],
      'deny_all': None,
      'enforce': None,
      'values': [{
          'allowed_values': ['EXTERNAL_1'],
          'denied_values': None
      }]
  }

  assert p3['rules'][2] == {
      'allow_all': 'TRUE',
      'condition': [{
          'description':
              'test condition2',
          'expression':
              'resource.matchTagId("tagKeys/12345", "tagValues/12345")',
          'location':
              'xxx',
          'title':
              'condition2'
      }],
      'deny_all': None,
      'enforce': None,
      'values': []
  }
