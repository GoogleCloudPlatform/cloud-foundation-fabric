# Copyright 2021 Google LLC
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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_firweall_policy(plan_runner):
  "Test boolean folder policy."
  policy = """
  {
    policy1 = {
      allow-ingress = {
        description = ""
        direction   = "INGRESS"
        action      = "allow"
        priority    = 100
        ranges      = ["10.0.0.0/8"]
        ports = {
          tcp = ["22"]
        }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
      deny-egress = {
        description = ""
        direction   = "EGRESS"
        action      = "deny"
        priority    = 200
        ranges      = ["192.168.0.0/24"]
        ports = {
          tcp = ["443"]
        }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
    }
  }
  """
  attachment = '{ iap_policy = "policy1" }'
  _, resources = plan_runner(FIXTURES_DIR, firewall_policies=policy,
                             firewall_policy_attachments=attachment)
  assert len(resources) == 5
  
  policies = [r for r in resources
           if r['type'] == 'google_compute_organization_security_policy']
  assert len(policies) == 1

  rules = [r for r in resources
           if r['type'] == 'google_compute_organization_security_policy_rule']
  assert len(rules) == 2

  rule_values = []
  for rule in rules:
    name = rule['name']
    index = rule['index']
    action = rule['values']['action']
    direction = rule['values']['direction']
    priority = rule['values']['priority']
    config = rule['values']['match']
    assert len(config) == 1
    config = config[0]['config']
    rule_values.append((name, index, action, direction, priority, config))

  assert sorted(rule_values) == sorted([
    ('rule', 'policy1-allow-ingress', 'allow', 'INGRESS', 100,[
      {
        'dest_ip_ranges': None,
        'layer4_config': [{'ip_protocol': 'tcp', 'ports': ['22']}],
        'src_ip_ranges': ['10.0.0.0/8']
      }]),
    ('rule', 'policy1-deny-egress', 'deny', 'EGRESS', 200, [
      {
        'dest_ip_ranges': ['192.168.0.0/24'],
        'layer4_config': [{'ip_protocol': 'tcp', 'ports': ['443']}],
        'src_ip_ranges': None
      }])
  ])


