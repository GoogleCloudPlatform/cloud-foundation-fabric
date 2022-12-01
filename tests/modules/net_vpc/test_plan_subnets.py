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

import yaml
from pathlib import Path


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


def test_subnets(generic_plan_validator):
  generic_plan_validator("modules/net-vpc", 'subnets.yaml',
                         ['common.tfvars', 'subnets.tfvars'])
