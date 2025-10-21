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
    # File comparison
    [
        "fast/stages/0-org-setup/datasets/classic/defaults.yaml",
        "fast/stages/0-org-setup/datasets/hardened/defaults.yaml",
    ],
    [
        "fast/stages/0-org-setup/datasets/classic/organization/.config.yaml",
        "fast/stages/0-org-setup/datasets/hardened/organization/.config.yaml",
    ],
    [
        "fast/stages/0-org-setup/datasets/classic/projects/core/billing-0.yaml",
        "fast/stages/0-org-setup/datasets/hardened/projects/core/billing-0.yaml",
    ],
    [
        "fast/stages/2-networking-a-simple/data/dns-policy-rules.yaml",
        "fast/stages/2-networking-b-nva/data/dns-policy-rules.yaml",
        "fast/stages/2-networking-c-separate-envs/data/dns-policy-rules.yaml",
    ],
    [
        "fast/stages/2-networking-a-simple/data/cidrs.yaml",
        "fast/stages/2-networking-b-nva/data/cidrs.yaml",
        "fast/stages/2-networking-c-separate-envs/data/cidrs.yaml",
    ],
    # Deep recursive folder comparison
    [
        "fast/stages/0-org-setup/datasets/classic/organization/custom-roles",
        "fast/stages/0-org-setup/datasets/hardened/organization/custom-roles",
    ],
    [
        "fast/stages/0-org-setup/datasets/classic/organization/tags",
        "fast/stages/0-org-setup/datasets/hardened/organization/tags",
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
