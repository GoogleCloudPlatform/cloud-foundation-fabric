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

def test_firewall_simple(plan_runner):
  "Test firewall rules from rules/common.yaml with no extra options."
  _, resources = plan_runner()
  assert len(resources) == 4
  assert set(r['type'] for r in resources) == set([
      'google_compute_firewall', 'time_static'
  ])
  firewall_values = [r['values'] for r in resources if r['type']
                     == 'google_compute_firewall']
  assert set([f['project'] for f in firewall_values]) == set(['my-project'])
  assert set([f['network'] for f in firewall_values]) == set(['my-network'])


def test_firewall_log_config(plan_runner):
  "Test firewall rules log configuration."
  log_config = """ {
      metadata = "INCLUDE_ALL_METADATA"
    }
    """
  log_config_value = [{"metadata": "INCLUDE_ALL_METADATA"}]
  _, resources = plan_runner(log_config=log_config)
  assert len(resources) == 4
  assert set(r['type'] for r in resources) == set([
      'google_compute_firewall', 'time_static'
  ])
  firewall_values = [r['values'] for r in resources if r['type']
                     == 'google_compute_firewall']
  assert all(f['log_config'] == log_config_value for f in firewall_values)
