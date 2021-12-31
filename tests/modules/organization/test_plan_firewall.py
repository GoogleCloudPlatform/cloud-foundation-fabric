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

_FACTORY = '''
{
  cidr_file = "data/firewall-cidrs.yaml"
  policy_name = "factory-1"
  rules_file = "data/firewall-rules.yaml"
}
'''
_POLICIES = '''
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
  policy2 = {
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
  }
  }
'''


def test_custom(plan_runner):
  'Test custom firewall policies.'
  _, resources = plan_runner(FIXTURES_DIR, firewall_policies=_POLICIES)
  assert len(resources) == 5
  policies = [r for r in resources
              if r['type'] == 'google_compute_firewall_policy']
  rules = [r for r in resources
           if r['type'] == 'google_compute_firewall_policy_rule']
  assert set(r['index'] for r in policies) == set([
      'policy1', 'policy2'
  ])
  assert set(r['index'] for r in rules) == set([
      'policy1-deny-egress', 'policy2-allow-ingress', 'policy1-allow-ingress'
  ])


def test_factory(plan_runner):
  'Test firewall policy factory.'
  _, resources = plan_runner(FIXTURES_DIR, firewall_policy_factory=_FACTORY)
  assert len(resources) == 3
  policies = [r for r in resources
              if r['type'] == 'google_compute_firewall_policy']
  rules = [r for r in resources
           if r['type'] == 'google_compute_firewall_policy_rule']
  assert set(r['index'] for r in policies) == set([
      'factory-1'
  ])
  assert set(r['index'] for r in rules) == set([
      'factory-1-allow-admins', 'factory-1-allow-ssh-from-iap'
  ])


def test_factory_name(plan_runner):
  'Test firewall policy factory default name.'
  factory = _FACTORY.replace('"factory-1"', 'null')
  _, resources = plan_runner(FIXTURES_DIR, firewall_policy_factory=factory)
  assert len(resources) == 3
  policies = [r for r in resources
              if r['type'] == 'google_compute_firewall_policy']
  assert set(r['index'] for r in policies) == set([
      'factory'
  ])


def test_combined(plan_runner):
  'Test combined rules.'
  _, resources = plan_runner(FIXTURES_DIR, firewall_policies=_POLICIES,
                             firewall_policy_factory=_FACTORY)
  assert len(resources) == 8
  policies = [r for r in resources
              if r['type'] == 'google_compute_firewall_policy']
  rules = [r for r in resources
           if r['type'] == 'google_compute_firewall_policy_rule']
  assert set(r['index'] for r in policies) == set([
      'factory-1', 'policy1', 'policy2'
  ])
  assert set(r['index'] for r in rules) == set([
      'factory-1-allow-admins', 'factory-1-allow-ssh-from-iap',
      'policy1-deny-egress', 'policy2-allow-ingress', 'policy1-allow-ingress'
  ])
