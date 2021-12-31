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


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_create_policy(plan_runner):
  "Test with auto-created policy."
  _, resources = plan_runner(FIXTURES_DIR)
  counts = {}
  for r in resources:
    n = f'{r["type"]}.{r["name"]}'
    counts[n] = counts.get(n, 0) + 1
  assert counts == {
      'google_access_context_manager_access_level.basic': 2,
      'google_access_context_manager_access_policy.default': 1,
      'google_access_context_manager_service_perimeter.bridge': 2,
      'google_access_context_manager_service_perimeter.regular': 2
  }


def test_use_policy(plan_runner):
  "Test with existing policy."
  _, resources = plan_runner(FIXTURES_DIR, access_policy_create="null",
                             access_policy="accessPolicies/foobar")
  counts = {}
  for r in resources:
    n = f'{r["type"]}.{r["name"]}'
    counts[n] = counts.get(n, 0) + 1
  assert counts == {
      'google_access_context_manager_access_level.basic': 2,
      'google_access_context_manager_service_perimeter.bridge': 2,
      'google_access_context_manager_service_perimeter.regular': 2
  }
