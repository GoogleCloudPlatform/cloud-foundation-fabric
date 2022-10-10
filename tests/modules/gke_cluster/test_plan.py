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


def test_standard(plan_runner):
  "Test resources created with variable defaults."
  _, resources = plan_runner()
  assert len(resources) == 1

  cluster_config = resources[0]['values']
  assert cluster_config['name'] == "cluster-1"
  assert cluster_config['network'] == "mynetwork"
  assert cluster_config['subnetwork'] == "mysubnet"
  assert cluster_config['enable_autopilot'] is None
  # assert 'service_account' not in node_config


def test_autopilot(plan_runner):
  "Test resources created with variable defaults."
  _, resources = plan_runner(enable_features='{ autopilot=true }')
  assert len(resources) == 1
  cluster_config = resources[0]['values']
  assert cluster_config['name'] == "cluster-1"
  assert cluster_config['network'] == "mynetwork"
  assert cluster_config['subnetwork'] == "mysubnet"
  assert cluster_config['enable_autopilot'] == True
  # assert 'service_account' not in node_config
