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

from .validate_policies import validate_policy_boolean, validate_policy_list


def test_policy_boolean(plan_runner):
  "Test boolean org policy."
  tfvars = 'test.orgpolicies-boolean.tfvars'
  _, resources = plan_runner(tf_var_file=tfvars)
  validate_policy_boolean(resources)


def test_policy_list(plan_runner):
  "Test list org policy."
  tfvars = 'test.orgpolicies-list.tfvars'
  _, resources = plan_runner(tf_var_file=tfvars)
  validate_policy_list(resources)


def test_factory_policy_boolean(plan_runner, tfvars_to_yaml, tmp_path):
  dest = tmp_path / 'policies.yaml'
  tfvars_to_yaml('fixture/test.orgpolicies-boolean.tfvars', dest,
                 'org_policies')
  _, resources = plan_runner(org_policies_data_path=f'"{tmp_path}"')
  validate_policy_boolean(resources)


def test_factory_policy_list(plan_runner, tfvars_to_yaml, tmp_path):
  dest = tmp_path / 'policies.yaml'
  tfvars_to_yaml('fixture/test.orgpolicies-list.tfvars', dest, 'org_policies')
  _, resources = plan_runner(org_policies_data_path=f'"{tmp_path}"')
  validate_policy_list(resources)
