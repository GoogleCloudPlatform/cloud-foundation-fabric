# Copyright 2023 Google LLC
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
def resources(plan_summary, version):
  # convert `version` to a boolean suitable for the `v2` variable
  v2 = {'v1': 'false', 'v2': 'true'}[version]
  summary = plan_summary('modules/cloud-function',
                         tf_var_files=['common.tfvars'], v2=v2)
  return summary


@pytest.mark.parametrize('version', ['v1', 'v2'])
def test_resource_count(resources):
  "Test number of resources created."
  assert resources.counts['resources'] == 3


@pytest.mark.parametrize('version', ['v1', 'v2'])
def test_iam(resources, version):
  "Test IAM binding resources."
  type = {
      'v1': 'google_cloudfunctions_function_iam_binding',
      'v2': 'google_cloudfunctions2_function_iam_binding'
  }[version]
  key = f'{type}.default["roles/cloudfunctions.invoker"]'
  binding = resources.values[key]
  assert binding['role'] == 'roles/cloudfunctions.invoker'
  assert binding['members'] == ['allUsers']
