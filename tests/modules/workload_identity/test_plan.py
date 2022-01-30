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
  assert len(resources) == 2


def test_pool(resources):
  "Test workload identity pool resources"
  pools = [r['values'] for r in resources if r['type']
                        == 'google_iam_workload_identity_pool' and r['name'] == 'pool']
  assert len(pools) == 1


def test_providers(resources):
  "Test workload identity pool provider resources"
  providers = [r['values'] for r in resources if r['type']
                     == 'google_iam_workload_identity_pool_provider' and r['name'] == 'providers']
  assert len(providers) == 1
