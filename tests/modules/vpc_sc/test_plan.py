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

import collections


def test_create_policy(plan_runner):
  "Test with auto-created policy."
  access_policy_create = '''{
    parent = "organizations/123456"
    title  = "vpcsc-policy"
  }'''
  _, resources = plan_runner(tf_var_file='test.regular.tfvars',
                             access_policy='null',
                             access_policy_create=access_policy_create)
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_access_context_manager_access_level.basic': 2,
      'google_access_context_manager_access_policy.default': 1,
      'google_access_context_manager_service_perimeter.bridge': 2,
      'google_access_context_manager_service_perimeter.regular': 2
  }


def test_use_policy(plan_runner):
  "Test with existing policy."
  _, resources = plan_runner(tf_var_file='test.regular.tfvars',
                             access_policy="accessPolicies/foobar")
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_access_context_manager_access_level.basic': 2,
      'google_access_context_manager_service_perimeter.bridge': 2,
      'google_access_context_manager_service_perimeter.regular': 2
  }
