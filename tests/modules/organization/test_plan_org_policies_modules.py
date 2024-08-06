# Copyright 2024 Google LLC
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

  diff1 = difflib.unified_diff(lines['project'], lines['folder'], 'project',
                               'folder', n=0)
  assert list(diff1) == [
      '--- project\n',
      '+++ folder\n',
      '@@ -17 +17 @@\n',
      '-# tfdoc:file:description Project-level organization policies.\n',
      '+# tfdoc:file:description Folder-level organization policies.\n',
      '@@ -79,2 +79,2 @@\n',
      '-  name   = "projects/${local.project.project_id}/policies/${each.value}"\n',
      '-  parent = "projects/${local.project.project_id}"\n',
      '+  name   = "${local.folder_id}/policies/${each.value}"\n',
      '+  parent = local.folder_id\n',
  ]

  diff2 = difflib.unified_diff(lines['folder'], lines['organization'], 'folder',
                               'organization', n=0)
  assert list(diff2) == [
      '--- folder\n',
      '+++ organization\n',
      '@@ -17 +17 @@\n',
      '-# tfdoc:file:description Folder-level organization policies.\n',
      '+# tfdoc:file:description Organization-level organization policies.\n',
      '@@ -79,2 +79,2 @@\n',
      '-  name   = "${local.folder_id}/policies/${each.value}"\n',
      '-  parent = local.folder_id\n',
      '+  name   = "${var.organization_id}/policies/${each.value}"\n',
      '+  parent = var.organization_id\n',
      '@@ -155,0 +156,9 @@\n',
      '+  depends_on = [\n',
      '+    google_organization_iam_binding.authoritative,\n',
      '+    google_organization_iam_binding.bindings,\n',
      '+    google_organization_iam_member.bindings,\n',
      '+    google_organization_iam_custom_role.roles,\n',
      '+    google_org_policy_custom_constraint.constraint,\n',
      '+    google_tags_tag_key.default,\n',
      '+    google_tags_tag_value.default,\n',
      '+  ]\n',
  ]
