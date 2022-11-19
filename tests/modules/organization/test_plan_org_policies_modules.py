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
import pathlib


def test_policy_implementation():
  '''Verify org policy implementation is the same (except minor
  differences) in the organization, folder and project modules.'''

  modules_path = pathlib.Path(__file__).parents[3] / 'modules'
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
      '   _factory_data_raw = merge([\n',
      '@@ -65,8 +65,8 @@\n',
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
      '   _factory_data_raw = merge([\n',
      '@@ -65,8 +65,8 @@\n',
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
      '@@ -139,4 +139,13 @@\n',
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
      '+    google_org_policy_custom_constraint.constraint,\n',
      '+  ]\n',
      ' }\n',
  ]
