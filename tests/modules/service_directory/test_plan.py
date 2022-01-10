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

import pytest


@pytest.fixture
def resources(plan_runner):
  _, resources = plan_runner()
  return resources


def test_resource_count(resources):
  "Test number of resources created."
  assert len(resources) == 9


def test_iam(resources):
  "Test IAM binding resources."
  bindings = [r['values'] for r in resources if r['type']
              == 'google_service_directory_namespace_iam_binding']
  assert len(bindings) == 1
  assert bindings[0]['role'] == 'roles/servicedirectory.viewer'


def test_services(resources):
  "Test service resources."
  services = [r['values'] for r in resources if r['type']
              == 'google_service_directory_service']
  assert len(services) == 2
  assert set(s['service_id'] for s in services) == set(['srv-one', 'srv-two'])


def test_service_iam(resources):
  "Test service IAM binding resources."
  bindings = [r['values'] for r in resources if r['type']
              == 'google_service_directory_service_iam_binding']
  assert len(bindings) == 2
  assert set(b['role'] for b in bindings) == set([
      'roles/servicedirectory.admin', 'roles/servicedirectory.editor'
  ])
