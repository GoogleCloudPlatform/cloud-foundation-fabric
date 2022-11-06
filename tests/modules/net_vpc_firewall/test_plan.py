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

import pytest


def test_defaults(plan_runner):
  "Test variable defaults."
  _, resources = plan_runner()
  assert len(resources) == 3
  assert set([r['type'] for r in resources]) == set(['google_compute_firewall'])
  assert set([r['values']['name'] for r in resources]) == set([
      'test-vpc-ingress-tag-http', 'test-vpc-ingress-tag-https',
      'test-vpc-ingress-tag-ssh'
  ])
  assert set([r['values']['project'] for r in resources
             ]) == set(['test-project'])
  assert set([r['values']['network'] for r in resources]) == set(['test-vpc'])


def test_rules(plan_runner):
  "Test custom rules."
  _, resources = plan_runner(tf_var_file='test.rules.tfvars')
  assert len(resources) == 3
  rules = {r['index']: r['values'] for r in resources}
  rule = rules['allow-ingress-ntp']
  assert rule['source_ranges'] == ['0.0.0.0/0']
  assert rule['allow'] == [{'ports': ['123'], 'protocol': 'udp'}]
  rule = rules['deny-egress-all']
  assert rule['destination_ranges'] == ['0.0.0.0/0']
  assert rule['deny'] == [{'ports': [], 'protocol': 'all'}]


def test_factory(plan_runner):
  "Test factory."
  factories_config = '''{
    cidr_tpl_file = "config/cidr_template.yaml"
    rules_folder  = "config/firewall"
  }'''
  _, resources = plan_runner(factories_config=factories_config)
  assert len(resources) == 4
  factory_rule = [
      r for r in resources if r["values"]["name"] == "allow-healthchecks"
  ][0]["values"]
  assert set(factory_rule["source_ranges"]) == set(
      ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"])
  assert set(factory_rule["target_tags"]) == set(["lb-backends"])
