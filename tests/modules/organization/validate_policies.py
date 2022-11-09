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


def validate_policy_boolean(resources):
  assert len(resources) == 2
  assert all(
      r['values']['parent'] == 'organizations/1234567890' for r in resources)
  policies = {
      r['index']: r['values']['spec'][0]
      for r in resources
      if r['type'] == 'google_org_policy_policy'
  }
  assert len(policies) == 2
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


def validate_policy_list(resources):
  assert len(resources) == 3
  assert all(
      r['values']['parent'] == 'organizations/1234567890' for r in resources)
  policies = {
      r['index']: r['values']['spec'][0]
      for r in resources
      if r['type'] == 'google_org_policy_policy'
  }
  assert len(policies) == 3
  p1 = policies['compute.vmExternalIpAccess']
  assert p1['inherit_from_parent'] is None
  assert p1['reset'] is None
  assert p1['rules'] == [{
      'allow_all': None,
      'condition': [],
      'deny_all': 'TRUE',
      'enforce': None,
      'values': []
  }]
  p2 = policies['iam.allowedPolicyMemberDomains']
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
  p3 = policies['compute.restrictLoadBalancerCreationForTypes']
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
          'expression': 'resource.matchTagId(aa, bb)',
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
          'description': 'test condition2',
          'expression': 'resource.matchTagId(cc, dd)',
          'location': 'xxx',
          'title': 'condition2'
      }],
      'deny_all': None,
      'enforce': None,
      'values': []
  }

def validate_policy_custom_constraints(resources):
  assert len(resources) == 2
  assert all(
      r['values']['parent'] == 'organizations/1234567890' for r in resources)
  constraints = {
      r['index']: r['values']
      for r in resources
      if r['type'] == 'google_org_policy_custom_constraint'
  }
  assert len(constraints) == 2
  c1 = constraints['custom.gkeEnableAutoUpgrade']
  assert c1['resource_types'][0] == 'container.googleapis.com/NodePool'
  assert c1['method_types'] == ['CREATE']
  assert c1['condition'] == 'resource.management.autoUpgrade == true'
  assert c1['action_type'] == 'ALLOW'
  
  c2 = constraints['custom.dataprocNoMoreThan10Workers']
  assert c2['resource_types'][0] == 'dataproc.googleapis.com/Cluster'
  assert c2['method_types'] == ['CREATE', 'UPDATE']
  assert c2['condition'] == 'resource.config.workerConfig.numInstances + resource.config.secondaryWorkerConfig.numInstances > 10'
  assert c2['action_type'] == 'DENY'
