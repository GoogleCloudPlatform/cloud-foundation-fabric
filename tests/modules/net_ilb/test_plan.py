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

_BACKENDS = '[{balancing_mode="CONNECTION", group="foo", failover=false}]'


def test_defaults(plan_runner):
  "Test variable defaults."
  _, resources = plan_runner(backends=_BACKENDS)
  assert len(resources) == 3
  resources = dict((r['type'], r['values']) for r in resources)
  fwd_rule = resources['google_compute_forwarding_rule']
  assert fwd_rule['load_balancing_scheme'] == 'INTERNAL'
  assert fwd_rule['all_ports']
  assert fwd_rule['allow_global_access'] is None
  backend = resources['google_compute_region_backend_service']
  assert len(backend['backend']) == 1
  assert backend['backend'][0]['group'] == 'foo'
  health_check = resources['google_compute_health_check']
  for k, v in health_check.items():
    if k == 'tcp_health_check':
      assert len(v) == 1
      assert v[0]['port_specification'] == 'USE_SERVING_PORT'
    elif k.endswith('_health_check'):
      assert len(v) == 0


def test_forwarding_rule(plan_runner):
  "Test forwarding rule variables."
  _, resources = plan_runner(backends=_BACKENDS, global_access='true',
                             ports="[80]")
  assert len(resources) == 3
  values = [
      r['values']
      for r in resources
      if r['type'] == 'google_compute_forwarding_rule'
  ][0]
  assert not values['all_ports']
  assert values['ports'] == ['80']
  assert values['allow_global_access']
