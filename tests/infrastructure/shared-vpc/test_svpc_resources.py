# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Test shared vpc resources in root module."


import pytest


@pytest.fixture(scope='module')
def mod(plan):
  return plan.modules['module.net-svpc-access']


def test_host_vpc(plan):
  "Test that the vpc project is set as shared vpc host."
  mod = plan.modules['module.net-vpc-host']
  resources = [v['values'] for v in mod.resources.values() if v['type'] ==
               'google_compute_shared_vpc_host_project']
  assert resources[0]['project'] == plan.outputs['host_project_id']


def test_service_projects(plan, mod):
  "Test that service projects are registered with the shared vpc."
  resources = [v['values'] for v in mod.resources.values() if v['type'] ==
               'google_compute_shared_vpc_service_project']
  assert len(resources) == 2
  assert set([r['host_project'] for r in resources]) == set(
      [plan.outputs['host_project_id']])
  assert sorted([r['service_project'] for r in resources]) == sorted(
      plan.outputs['service_project_ids'].values())


def test_subnet_users(plan, mod):
  "Test that the network user role is assigned on subnets."
  resources = [v['values'] for v in mod.resources.values() if v['type'] ==
               'google_compute_subnetwork_iam_binding']
  assert len(resources) == 2
  assert set([r['project'] for r in resources]) == set(
      [plan.outputs['host_project_id']])
  assert sorted([r['subnetwork'] for r in resources]) == ['gce', 'gke']


def test_service_agent(plan, mod):
  "Test that the service agent role is assigned for gke only."
  resources = [v['values'] for v in mod.resources.values() if v['type'] ==
               'google_project_iam_binding']
  assert resources[0] == {
      'project': plan.outputs['host_project_id'],
      'role': 'roles/container.hostServiceAgentUser'
  }
