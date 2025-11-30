#!/usr/bin/env python3

# Copyright 2025 Google LLC
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
#

import filecmp
import sys
import os

# List of folders and files that are expected to have same content
duplicates = [
    # file comparison
    [
        "fast/stages/0-org-setup/datasets/classic/defaults.yaml",
        "fast/stages/0-org-setup/datasets/hardened/defaults.yaml",
    ],
    # deep recursive folder comparison
    [
        "fast/stages/0-org-setup/datasets/classic/organization/custom-roles",
        "fast/stages/0-org-setup/datasets/hardened/organization/custom-roles",
    ],
    [
        "fast/stages/0-org-setup/datasets/classic/organization/tags",
        "fast/stages/0-org-setup/datasets/hardened/organization/tags",
    ],
    # schemas
    [
        "fast/stages/1-vpcsc/schemas/access-level.schema.json",
        "modules/vpc-sc/schemas/access-level.schema.json",
    ],
    [
        "fast/stages/3-data-platform-dev/schemas/aspect-type.schema.json",
        "modules/dataplex-aspect-types/schemas/aspect-type.schema.json",
    ],
    [
        "fast/stages/2-project-factory/schemas/budget.schema.json",
        "fast/stages/0-org-setup/schemas/budget.schema.json",
        "modules/billing-account/schemas/budget.schema.json",
        "modules/project-factory/schemas/budget.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/custom-constraint.schema.json",
        "modules/organization/schemas/org-policy-custom-constraint.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/custom-role.schema.json",
        "modules/project/schemas/custom-role.schema.json",
        "modules/organization/schemas/custom-role.schema.json",
    ],
    [
        "fast/stages/1-vpcsc/schemas/egress-policy.schema.json",
        "modules/vpc-sc/schemas/egress-policy.schema.json",
    ],
    [
        "fast/stages/2-networking/schemas/firewall-rules.schema.json",
        "modules/net-vpc-firewall/schemas/firewall-rules.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/folder.schema.json",
        "fast/stages/2-networking/schemas/folder.schema.json",
        "fast/stages/2-project-factory/schemas/folder.schema.json",
        "fast/stages/2-security/schemas/folder.schema.json",
        "modules/project-factory/schemas/folder.schema.json",
    ],
    [
        "fast/stages/1-vpcsc/schemas/ingress-policy.schema.json",
        "modules/vpc-sc/schemas/ingress-policy.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/org-policies.schema.json",
        "modules/folder/schemas/org-policies.schema.json",
        "modules/project/schemas/org-policies.schema.json",
        "modules/organization/schemas/org-policies.schema.json",
    ],
    [
        "modules/folder/schemas/pam-entitlements.schema.json",
        "modules/project/schemas/pam-entitlements.schema.json",
        "modules/organization/schemas/pam-entitlements.schema.json",
    ],
    [
        "fast/stages/1-vpcsc/schemas/perimeter.schema.json",
        "modules/vpc-sc/schemas/perimeter.schema.json",
    ],
    [
        "modules/project-factory/schemas/project.schema.json",
        "fast/stages/0-org-setup/schemas/project.schema.json",
        "fast/stages/2-networking/schemas/project.schema.json",
        "fast/stages/2-project-factory/schemas/project.schema.json",
        "fast/stages/2-security/schemas/project.schema.json",
    ],
    [
        "modules/folder/schemas/scc-sha-custom-modules.schema.json",
        "modules/project/schemas/scc-sha-custom-modules.schema.json",
        "modules/organization/schemas/scc-sha-custom-modules.schema.json",
    ],
    [
        "fast/stages/2-networking/schemas/subnet.schema.json",
        "modules/net-vpc/schemas/subnet.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/tags.schema.json",
        "modules/project/schemas/tags.schema.json",
        "modules/organization/schemas/tags.schema.json",
    ],
    [
        "modules/cloud-function-v1/bundle.tf",
        "modules/cloud-function-v2/bundle.tf",
    ],
    [
        "modules/agent-engine/serviceaccount.tf",
        "modules/cloud-function-v1/serviceaccount.tf",
        "modules/cloud-function-v2/serviceaccount.tf",
        "modules/cloud-run-v2/serviceaccount.tf",
    ],
    [
        "modules/cloud-function-v1/variables-serviceaccount.tf",
        "modules/cloud-function-v2/variables-serviceaccount.tf",
        "modules/cloud-run-v2/variables-serviceaccount.tf",
    ],
    [
        "modules/cloud-function-v1/variables-vpcconnector.tf",
        "modules/cloud-function-v2/variables-vpcconnector.tf",
        "modules/cloud-run-v2/variables-vpcconnector.tf",
    ],
    [
        "modules/cloud-function-v1/vpcconnector.tf",
        "modules/cloud-function-v2/vpcconnector.tf",
        "modules/cloud-run-v2/vpcconnector.tf",
    ],
]


def check_dir_diff(dcmp):
  """
    Recursively checks a filecmp.dircmp object for any differences.
    Returns True if a difference is found, False otherwise.
    """
  diff_found = False

  if dcmp.left_only:
    print(f"[DIFF] Only in {dcmp.left}: {dcmp.left_only}")
    diff_found = True
  if dcmp.right_only:
    print(f"[DIFF] Only in {dcmp.right}: {dcmp.right_only}")
    diff_found = True
  if dcmp.diff_files:
    print(f"[DIFF] Mismatched files: {dcmp.diff_files}")
    diff_found = True

  for sub_dcmp in dcmp.subdirs.values():
    if check_dir_diff(sub_dcmp):
      diff_found = True

  return diff_found


has_diff = False

for group in duplicates:
  first = group[0]
  if not os.path.exists(first):
    print(f"[ERROR] Path not found: {first}. Skipping group.")
    has_diff = True
    continue

  is_dir = os.path.isdir(first)
  for second in group[1:]:
    if not os.path.exists(second):
      print(f"[DIFF] Path not found: {second}")
      has_diff = True
      continue

    if is_dir != os.path.isdir(second):
      print(f"[DIFF] Type mismatch: {first} is {'DIR' if is_dir else 'FILE'}, "
            f"but {second} is {'DIR' if os.path.isdir(second) else 'FILE'}.")
      has_diff = True
      continue

    if is_dir:
      dcmp = filecmp.dircmp(first, second)
      if check_dir_diff(dcmp):
        print(
            f"[DIFF] Found differences between directories {first} and {second}"
        )
        has_diff = True
    else:
      if not filecmp.cmp(first, second, shallow=False):
        print(f"[DIFF] Files are different: {first} and {second}")
        has_diff = True

if has_diff:
  print("\nCheck finished: Found differences.")
  sys.exit(1)
