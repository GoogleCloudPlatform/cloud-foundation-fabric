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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_address(plan_runner):
  nics = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = false,
    addresses  = {external=null, internal="10.0.0.2"}
  }]
  '''
  _, resources = plan_runner(FIXTURES_DIR, network_interfaces=nics)
  assert len(resources) == 1
  n = resources[0]['values']['network_interface'][0]
  assert n['network_ip'] == "10.0.0.2"
  assert n['access_config'] == []


def test_nat_address(plan_runner):
  nics = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = true,
    addresses  = {external="8.8.8.8", internal=null}
  }]
  '''
  _, resources = plan_runner(FIXTURES_DIR, network_interfaces=nics)
  assert len(resources) == 1
  n = resources[0]['values']['network_interface'][0]
  assert 'network_ip' not in n
  assert n['access_config'][0]['nat_ip'] == '8.8.8.8'
