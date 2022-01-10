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
  association = '{policy1="policy1"}'
  _, resources = plan_runner(firewall_policies=policy,
                             firewall_policy_association=association)
  assert len(resources) == 5

  policies = [r for r in resources
              if r['type'] == 'google_compute_firewall_policy']
  assert len(policies) == 1

  rules = [r for r in resources
           if r['type'] == 'google_compute_firewall_policy_rule']
  assert len(rules) == 2

  rule_values = []
  for rule in rules:
    name = rule['name']
    index = rule['index']
    action = rule['values']['action']
    direction = rule['values']['direction']
    priority = rule['values']['priority']
    match = rule['values']['match']
    rule_values.append((name, index, action, direction, priority, match))

  assert sorted(rule_values) == sorted([
      ('rule', 'policy1-allow-ingress', 'allow', 'INGRESS', 100, [
          {
              'dest_ip_ranges': None,
              'layer4_configs': [{'ip_protocol': 'tcp', 'ports': ['22']}],
              'src_ip_ranges': ['10.0.0.0/8']
          }]),
      ('rule', 'policy1-deny-egress', 'deny', 'EGRESS', 200, [
          {
              'dest_ip_ranges': ['192.168.0.0/24'],
              'layer4_configs': [{'ip_protocol': 'tcp', 'ports': ['443']}],
              'src_ip_ranges': None
          }])
  ])
