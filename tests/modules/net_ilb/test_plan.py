# Copyright 2020 Google LLC
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

_BACKENDS = '[{balancing_mode="CONNECTION", group="foo", failover=false}]'


def test_defaults(plan_runner):
  "Test variable defaults."
  _, resources = plan_runner(FIXTURES_DIR, backends=_BACKENDS)
  assert len(resources) == 3
  fwd_rule = [r['values'] for r in resources if r['type']
              == 'google_compute_forwarding_rule'][0]
  assert fwd_rule['load_balancing_scheme'] == 'INTERNAL'
  assert fwd_rule['all_ports']
  assert fwd_rule['allow_global_access'] is None


def test_forwarding_rule(plan_runner):
  "Test forwarding rule variables."
  _, resources = plan_runner(
      FIXTURES_DIR, backends=_BACKENDS, global_access='true', ports="[80]")
  assert len(resources) == 3
  values = [r['values'] for r in resources if r['type']
            == 'google_compute_forwarding_rule'][0]
  assert not values['all_ports']
  assert values['ports'] == ['80']
  assert values['allow_global_access']
