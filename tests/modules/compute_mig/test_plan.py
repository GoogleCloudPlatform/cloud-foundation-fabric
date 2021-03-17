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


def test_defaults(plan_runner):
  "Test variable defaults."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  mig = resources[0]
  assert mig['type'] == 'google_compute_instance_group_manager'
  assert mig['values']['target_size'] == 2
  assert mig['values']['zone']
  _, resources = plan_runner(FIXTURES_DIR, regional='true')
  assert len(resources) == 1
  mig = resources[0]
  assert mig['type'] == 'google_compute_region_instance_group_manager'
  assert mig['values']['target_size'] == 2
  assert mig['values']['region']


def test_health_check(plan_runner):
  "Test health check resource."
  health_check_config = '{type="tcp", check={port=80}, config=null, logging=false}'
  _, resources = plan_runner(
      FIXTURES_DIR, health_check_config=health_check_config)
  assert len(resources) == 2
  assert any(r['type'] == 'google_compute_health_check' for r in resources)


def test_autoscaler(plan_runner):
  "Test autoscaler resource."
  autoscaler_config = (
      '{'
      'max_replicas=3, min_replicas=1, cooldown_period=60,'
      'cpu_utilization_target=65, load_balancing_utilization_target=null,'
      'metric=null'
      '}'
  )
  _, resources = plan_runner(
      FIXTURES_DIR, autoscaler_config=autoscaler_config)
  assert len(resources) == 2
  autoscaler = resources[0]
  assert autoscaler['type'] == 'google_compute_autoscaler'
  assert autoscaler['values']['autoscaling_policy'] == [{
      'cooldown_period': 60,
      'cpu_utilization': [{'predictive_method': 'NONE', 'target': 65}],
      'load_balancing_utilization': [],
      'max_replicas': 3,
      'metric': [],
      'min_replicas': 1,
      'mode': 'ON',
      'scale_in_control': [],
      'scaling_schedules': [],
  }]
  _, resources = plan_runner(
      FIXTURES_DIR, autoscaler_config=autoscaler_config, regional='true')
  assert len(resources) == 2
  autoscaler = resources[0]
  assert autoscaler['type'] == 'google_compute_region_autoscaler'
