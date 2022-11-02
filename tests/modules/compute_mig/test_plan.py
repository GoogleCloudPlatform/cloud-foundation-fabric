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


def test_defaults(plan_runner):
  "Test variable defaults."
  _, resources = plan_runner()
  assert len(resources) == 1
  print(resources[0]['type'])
  mig = resources[0]
  assert mig['type'] == 'google_compute_instance_group_manager'
  assert mig['values']['target_size'] == 2
  assert mig['values']['zone']
  _, resources = plan_runner(location='"europe-west1"')
  assert len(resources) == 1
  mig = resources[0]
  assert mig['type'] == 'google_compute_region_instance_group_manager'
  assert mig['values']['target_size'] == 2
  assert mig['values']['region']


def test_health_check(plan_runner):
  "Test health check resource."
  health_check_config = '''{
    enable_logging = true
    tcp = {
      port = 80
    }
  }'''
  _, resources = plan_runner(health_check_config=health_check_config)
  assert len(resources) == 2
  assert any(r['type'] == 'google_compute_health_check' for r in resources)


def test_autoscaler(plan_runner):
  "Test autoscaler resource."
  autoscaler_config = '''{
    colldown_period = 60
    max_replicas    = 3
    min_replicas    = 1
    scaling_signals = {
      cpu_utilization = {
        target = 65
      }
    }
  }'''
  _, resources = plan_runner(autoscaler_config=autoscaler_config)
  assert len(resources) == 2
  autoscaler = resources[0]
  assert autoscaler['type'] == 'google_compute_autoscaler'
  assert autoscaler['values']['autoscaling_policy'] == [{
      'cooldown_period': 60,
      'cpu_utilization': [{
          'predictive_method': 'NONE',
          'target': 65
      }],
      'load_balancing_utilization': [],
      'max_replicas': 3,
      'metric': [],
      'min_replicas': 1,
      'mode': 'ON',
      'scale_in_control': [],
      'scaling_schedules': [],
  }]
  _, resources = plan_runner(autoscaler_config=autoscaler_config,
                             location='"europe-west1"')
  assert len(resources) == 2
  autoscaler = resources[0]
  assert autoscaler['type'] == 'google_compute_region_autoscaler'


def test_stateful_mig(plan_runner):
  "Test stateful instances - mig."

  stateful_disks = '''{
    persistent-disk-1 = null
  }'''
  _, resources = plan_runner(stateful_disks=stateful_disks)
  assert len(resources) == 1
  statefuldisk = resources[0]
  assert statefuldisk['type'] == 'google_compute_instance_group_manager'
  assert statefuldisk['values']['stateful_disk'] == [{
      'device_name': 'persistent-disk-1',
      'delete_rule': 'NEVER',
  }]


def test_stateful_instance(plan_runner):
  "Test stateful instances - instance."
  stateful_config = '''{
    instance-1 = {
      most_disruptive_action   = "REPLACE",
      preserved_state = {
        disks = {
          persistent-disk-1 = {
            source = "test-disk"
          }
        }
        metadata = { foo = "bar" }
      }
    }
  }'''
  _, resources = plan_runner(stateful_config=stateful_config)
  assert len(resources) == 2
  instanceconfig = resources[0]
  assert instanceconfig['type'] == 'google_compute_instance_group_manager'
  instanceconfig = resources[1]
  assert instanceconfig['type'] == 'google_compute_per_instance_config'

  assert instanceconfig['values']['preserved_state'] == [{
      'disk': [{
          'device_name': 'persistent-disk-1',
          'delete_rule': 'NEVER',
          'source': 'test-disk',
          'mode': 'READ_WRITE',
      }],
      'metadata': {
          'foo': 'bar'
      }
  }]
  assert instanceconfig['values']['minimal_action'] == 'NONE'
  assert instanceconfig['values']['most_disruptive_allowed_action'] == 'REPLACE'
  assert instanceconfig['values']['remove_instance_state_on_destroy'] == False
