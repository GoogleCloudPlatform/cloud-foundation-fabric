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

import difflib
from pathlib import Path

import hcl2
import yaml

BOOLEAN_POLICIES = '''{
  "iam.disableServiceAccountKeyCreation" = {
    enforce = true
  }
  "iam.disableServiceAccountKeyUpload" = {
    enforce = false
    rules = [
      {
        condition = {
          expression  = "resource.matchTagId(aa, bb)"
          title       = "condition"
          description = "test condition"
          location    = "xxx"
        }
        enforce = true
      }
    ]
  }
}'''

LIST_POLICIES = '''{
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
          expression  = "resource.matchTagId(aa, bb)"
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
          expression  = "resource.matchTagId(cc, dd)"
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


def test_policy_boolean(plan_runner):
  "Test boolean org policy."
  _, resources = plan_runner(org_policies=BOOLEAN_POLICIES)
  validate_policy_boolean_resources(resources)


def test_policy_list(plan_runner):
  "Test list org policy."
  _, resources = plan_runner(org_policies=LIST_POLICIES)
  validate_policy_list_resources(resources)


def test_policy_boolean_factory(plan_runner, tmp_path):
  # convert hcl policies to yaml
  hcl_policies = f'p = {BOOLEAN_POLICIES}'
  yaml_policies = yaml.dump(hcl2.loads(hcl_policies)['p'])

  yaml_file = tmp_path / 'policies.yaml'
  yaml_file.write_text(yaml_policies)

  _, resources = plan_runner(org_policies_data_path=f'"{tmp_path}"')
  validate_policy_boolean_resources(resources)


def test_policy_list_factory(plan_runner, tmp_path):
  # convert hcl policies to yaml
  hcl_policies = f'p = {LIST_POLICIES}'
  yaml_policies = yaml.dump(hcl2.loads(hcl_policies)['p'])

  yaml_file = tmp_path / 'policies.yaml'
  yaml_file.write_text(yaml_policies)

  _, resources = plan_runner(org_policies_data_path=f'"{tmp_path}"')
  validate_policy_list_resources(resources)


def validate_policy_boolean_resources(resources):
  assert len(resources) == 2
  policies = [r for r in resources if r['type'] == 'google_org_policy_policy']
  assert len(policies) == 2
  assert all(
      x['values']['parent'] == 'organizations/1234567890' for x in policies)

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
          'expression': 'resource.matchTagId(aa, bb)',
          'location': 'xxx',
          'title': 'condition'
      }],
      'deny_all': None,
      'enforce': 'TRUE',
      'values': []
  }


def validate_policy_list_resources(resources):
  assert len(resources) == 3

  policies = [r for r in resources if r['type'] == 'google_org_policy_policy']
  assert len(policies) == 3
  assert all(
      x['values']['parent'] == 'organizations/1234567890' for x in policies)

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


def test_policy_implementation(plan_runner):
  '''Verify org policy implementation is the same (except minor
  differences) in the organization, folder and project modules.'''

  modules_path = Path(__file__).parents[3] / 'modules'
  lines = {}
  for module in ['project', 'folder', 'organization']:
    path = modules_path / module / 'organization-policies.tf'
    lines[module] = path.open().readlines()

  diff1 = difflib.unified_diff(lines['project'], lines['folder'])
  assert list(diff1) == [
      '--- \n',
      '+++ \n',
      '@@ -14,7 +14,7 @@\n',
      '  * limitations under the License.\n',
      '  */\n',
      ' \n',
      '-# tfdoc:file:description Project-level organization policies.\n',
      '+# tfdoc:file:description Folder-level organization policies.\n',
      ' \n',
      ' locals {\n',
      '   _factory_data_raw = (\n',
      '@@ -69,8 +69,8 @@\n',
      '   org_policies = {\n',
      '     for k, v in local._org_policies :\n',
      '     k => merge(v, {\n',
      '-      name   = "projects/${local.project.project_id}/policies/${k}"\n',
      '-      parent = "projects/${local.project.project_id}"\n',
      '+      name   = "${local.folder.name}/policies/${k}"\n',
      '+      parent = local.folder.name\n',
      ' \n',
      '       is_boolean_policy = v.allow == null && v.deny == null\n',
      '       has_values = (\n',
  ]

  diff2 = difflib.unified_diff(lines['folder'], lines['organization'])
  assert list(diff2) == [
      '--- \n',
      '+++ \n',
      '@@ -14,7 +14,7 @@\n',
      '  * limitations under the License.\n',
      '  */\n',
      ' \n',
      '-# tfdoc:file:description Folder-level organization policies.\n',
      '+# tfdoc:file:description Organization-level organization policies.\n',
      ' \n',
      ' locals {\n',
      '   _factory_data_raw = (\n',
      '@@ -69,8 +69,8 @@\n',
      '   org_policies = {\n',
      '     for k, v in local._org_policies :\n',
      '     k => merge(v, {\n',
      '-      name   = "${local.folder.name}/policies/${k}"\n',
      '-      parent = local.folder.name\n',
      '+      name   = "${var.organization_id}/policies/${k}"\n',
      '+      parent = var.organization_id\n',
      ' \n',
      '       is_boolean_policy = v.allow == null && v.deny == null\n',
      '       has_values = (\n',
      '@@ -143,4 +143,12 @@\n',
      '       }\n',
      '     }\n',
      '   }\n',
      '+\n',
      '+  depends_on = [\n',
      '+    google_organization_iam_audit_config.config,\n',
      '+    google_organization_iam_binding.authoritative,\n',
      '+    google_organization_iam_custom_role.roles,\n',
      '+    google_organization_iam_member.additive,\n',
      '+    google_organization_iam_policy.authoritative,\n',
      '+  ]\n',
      ' }\n',
  ]
