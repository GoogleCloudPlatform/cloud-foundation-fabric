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

DATA_FOLDER = "data"


def test_subnet_factory(plan_runner):
  "Test subnet factory."
  _, resources = plan_runner(data_folder=DATA_FOLDER)
  assert len(resources) == 3
  subnets = [
      r['values'] for r in resources if r['type'] == 'google_compute_subnetwork'
  ]
  assert {s['name'] for s in subnets} == {'factory-subnet', 'factory-subnet2'}
  assert {len(s['secondary_ip_range']) for s in subnets} == {0, 1}
  assert {s['private_ip_google_access'] for s in subnets} == {True, False}


def test_subnets(plan_runner):
  "Test subnets variable."
  _, resources = plan_runner(tf_var_file='test.subnets.tfvars')
  assert len(resources) == 7
  subnets = [
      r['values'] for r in resources if r['type'] == 'google_compute_subnetwork'
  ]
  assert {s['name'] for s in subnets} == {'a', 'b', 'c', 'd'}
  assert {len(s['secondary_ip_range']) for s in subnets} == {0, 0, 2, 0}
  log_config = {s['name']: s['log_config'] for s in subnets if s['log_config']}
  assert log_config == {
      'd': [{
          'aggregation_interval': 'INTERVAL_10_MIN',
          'filter_expr': 'true',
          'flow_sampling': 0.5,
          'metadata': 'INCLUDE_ALL_METADATA',
          'metadata_fields': None
      }]
  }
  bindings = {
      r['index']: r['values']
      for r in resources
      if r['type'] == 'google_compute_subnetwork_iam_binding'
  }
  assert bindings == {
      'europe-west1/a.roles/compute.networkUser': {
          'condition': [],
          'members': ['group:g-a@example.com', 'user:a@example.com'],
          'project': 'test-project',
          'region': 'europe-west1',
          'role': 'roles/compute.networkUser',
          'subnetwork': 'a'
      },
      'europe-west1/c.roles/compute.networkUser': {
          'condition': [],
          'members': ['group:g-c@example.com', 'user:c@example.com'],
          'project': 'test-project',
          'region': 'europe-west1',
          'role': 'roles/compute.networkUser',
          'subnetwork': 'c'
      },
  }
