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

import tftest


def test_single_range(plan_runner):
  "Test single PSN range."
  _, resources = plan_runner(psn_ranges='["172.16.100.0/24"]')
  assert len(resources) == 3


def test_multi_range(plan_runner):
  "Test multiple PSN ranges."
  _, resources = plan_runner(psn_ranges='["172.16.100.0/24", "172.16.101.0/24"]')
  assert len(resources) == 4


def test_validation(plan_runner):
  "Test PSN variable validation."
  try:
    plan_runner(psn_ranges='["foobar"]')
  except tftest.TerraformTestError as e:
    assert 'Invalid value for variable' in e.args[0]
