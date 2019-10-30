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

"Test service account creation in root module."


import pytest


@pytest.fixture(scope='module')
def mod(plan):
  return plan.modules['module.service-accounts-tf-environments']


def test_accounts(plan, mod):
  "One service account per environment should be created."
  environments = plan.variables['environments']
  prefix = plan.variables['prefix']
  resources = [
      v for k, v in mod.resources.items() if 'google_service_account.' in k]
  assert len(resources) == len(environments)
  assert sorted([res['values']['account_id'] for res in resources]) == sorted([
      '%s-%s' % (prefix, env) for env in environments])
