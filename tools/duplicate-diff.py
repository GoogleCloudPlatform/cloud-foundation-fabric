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

duplicates = [  #
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
        "fast/stages/2-networking-a-simple/schemas/firewall-policy-rules.schema.json",
        "fast/stages/2-networking-c-separate-envs/schemas/firewall-policy-rules.schema.json",
        "fast/stages/2-networking-b-nva/schemas/firewall-policy-rules.schema.json",
        "modules/net-firewall-policy/schemas/firewall-policy-rules.schema.json",
    ],
    [
        "fast/stages/2-networking-a-simple/schemas/firewall-rules.schema.json",
        "fast/stages/2-networking-c-separate-envs/schemas/firewall-rules.schema.json",
        "fast/stages/2-networking-b-nva/schemas/firewall-rules.schema.json",
        "modules/net-vpc-firewall/schemas/firewall-rules.schema.json",
    ],
    [
        "fast/stages/2-project-factory/schemas/folder.schema.json",
        "fast/stages/0-org-setup/schemas/folder.schema.json",
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
        "fast/stages/2-project-factory/schemas/project.schema.json",
        "fast/stages/0-org-setup/schemas/project.schema.json",
        "fast/stages/2-security/schemas/project.schema.json",
        "modules/project-factory/schemas/project.schema.json",
    ],
    [
        "modules/folder/schemas/scc-sha-custom-modules.schema.json",
        "modules/project/schemas/scc-sha-custom-modules.schema.json",
        "modules/organization/schemas/scc-sha-custom-modules.schema.json",
    ],
    [
        "fast/stages/2-networking-a-simple/schemas/subnet.schema.json",
        "fast/stages/2-networking-c-separate-envs/schemas/subnet.schema.json",
        "fast/stages/2-networking-b-nva/schemas/subnet.schema.json",
        "modules/net-vpc/schemas/subnet.schema.json",
    ],
    [
        "fast/stages/0-org-setup/schemas/tags.schema.json",
        "modules/project/schemas/tags.schema.json",
        "modules/organization/schemas/tags.schema.json",
    ],
]

for group in duplicates:
  first = group[0]
  for second in group[1:]:
    if not filecmp.cmp(first, second):  # true if files are the same
      print(f'found diff between {first} and {second}')
      sys.exit(1)
