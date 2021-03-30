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


def test_no_addresses(plan_runner):
  network_interfaces = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = false,
    addresses  = {external=[], internal=[]}
    alias_ips  = null
  }]
  '''
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=2, network_interfaces=network_interfaces)
  assert len(resources) == 2


def test_internal_addresses(plan_runner):
  network_interfaces = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = false,
    addresses  = {external=[], internal=["1.1.1.2", "1.1.1.3"]}
    alias_ips  = null
  }]
  '''
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=2, network_interfaces=network_interfaces)
  assert [r['values']['network_interface'][0]['network_ip']
          for r in resources] == ["1.1.1.2", "1.1.1.3"]


def test_internal_addresses_nat(plan_runner):
  network_interfaces = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = true,
    addresses  = {external=[], internal=["1.1.1.2", "1.1.1.3"]}
    alias_ips  = null
  }]
  '''
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=2, network_interfaces=network_interfaces)
  assert [r['values']['network_interface'][0]['network_ip']
          for r in resources] == ["1.1.1.2", "1.1.1.3"]


def test_all_addresses(plan_runner):
  network_interfaces = '''[{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = true,
    addresses  = {external=["2.2.2.2", "2.2.2.3"], internal=["1.1.1.2", "1.1.1.3"]}
    alias_ips  = null
  }]
  '''
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=2, network_interfaces=network_interfaces)
  assert [r['values']['network_interface'][0]['access_config'][0]['nat_ip']
          for r in resources] == ["2.2.2.2", "2.2.2.3"]
