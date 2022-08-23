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

def test_svpc(_plan_runner):
  "Test Shared VPC service project attachment."
  fixture_path = os.path.join(os.path.dirname(__file__), 'fixture')
  plan = _plan_runner(fixture_path=fixture_path, _test_service_project='true')
  modules = [m for m in plan.root_module['child_modules']]
  resources = [r for r in modules[0]['resources'] if r['address'] == 'module.test.google_compute_shared_vpc_host_project.shared_vpc_host[0]']
  assert len(resources) == 1
  print(modules[1]['resources'])
  resources = [r for r in modules[1]['resources'] if r['address'] == 'module.test-svpc-service[0].google_compute_shared_vpc_service_project.shared_vpc_service[0]']
  assert len(resources) == 1
