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


def test_plan(e2e_plan_runner):
  "Check for a clean plan"
  modules, resources = e2e_plan_runner()
  assert len(modules) > 0 and len(resources) > 0


def test_plan_service_accounts(e2e_plan_runner):
  "Check for a clean plan"
  service_accounts = '''{
    sa-001 = []
    sa-002 = ["roles/owner"]
  }'''
  service_accounts_iam = '''{
    sa-002 = {
      "roles/iam.serviceAccountTokenCreator" = ["group:team-1@example.com"]
    }
  }'''
  modules, resources = e2e_plan_runner(
      service_accounts=service_accounts,
      service_accounts_iam=service_accounts_iam)
  assert len(modules) > 0 and len(resources) > 0
