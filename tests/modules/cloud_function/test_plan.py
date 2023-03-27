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
def resources(plan_runner, version):
  # convert `version` to a boolean suitable for the `v2` variable
  v2 = {'v1': 'false', 'v2': 'true'}[version]
  _, resources = plan_runner(v2=v2)
  return resources


@pytest.mark.parametrize('version', ['v1', 'v2'])
def test_resource_count(resources):
  "Test number of resources created."
  assert len(resources) == 3


@pytest.mark.parametrize('version', ['v1', 'v2'])
def test_iam(resources, version):
  "Test IAM binding resources."

  types = {
      'v1': 'google_cloudfunctions_function_iam_binding',
      'v2': 'google_cloudfunctions2_function_iam_binding'
  }

  bindings = [r['values'] for r in resources if r['type'] == types[version]]
  assert len(bindings) == 1
  assert bindings[0]['role'] == 'roles/cloudfunctions.invoker'
  assert bindings[0]['members'] == ['allUsers']
