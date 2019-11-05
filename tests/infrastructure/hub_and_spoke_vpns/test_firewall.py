# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Test firewall resources creation in root module."


import pytest


@pytest.fixture(scope='module')
def firewall_modules(plan):
  return [v for k, v in plan.modules.items() if k.startswith('module.firewall-')]


def test_firewall_rules(plan, firewall_modules):
  "Test that the hub and spoke VPCs have allow-admin firewall rules"
  source_ranges = []
  for k in plan.variables:
    if not k.endswith('_subnets'):
      continue
    source_ranges += [s['subnet_ip'] for s in plan.variables[k]]
  for mod in firewall_modules:
    allow_admins_resource = mod.resources['google_compute_firewall.allow-admins[0]']
    allow_ssh = mod.resources['google_compute_firewall.allow-tag-ssh[0]']
    assert allow_admins_resource['values']['source_ranges'] == source_ranges
    assert allow_ssh['values']['source_ranges'] == ['0.0.0.0/0']
