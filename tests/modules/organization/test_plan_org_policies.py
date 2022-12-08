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

import pathlib

import pytest

_params = ['boolean', 'list']


@pytest.mark.parametrize('policy_type', _params)
def test_policy_factory(plan_summary, tfvars_to_yaml, tmp_path, policy_type):
  dest = tmp_path / 'policies.yaml'
  tfvars_to_yaml(f'org_policies_{policy_type}.tfvars', dest, 'org_policies')
  tfvars_plan = plan_summary(
      'modules/organization',
      tf_var_files=['common.tfvars', f'org_policies_{policy_type}.tfvars'])
  yaml_plan = plan_summary('modules/organization',
                           tf_var_files=['common.tfvars'],
                           org_policies_data_path=f'{tmp_path}')
  assert tfvars_plan.values == yaml_plan.values


def test_custom_constraint_factory(plan_summary, tfvars_to_yaml, tmp_path):
  dest = tmp_path / 'constraints.yaml'
  tfvars_to_yaml(f'org_policies_custom_constraints.tfvars', dest,
                 'org_policy_custom_constraints')
  tfvars_plan = plan_summary(
      'modules/organization',
      tf_var_files=['common.tfvars', f'org_policies_custom_constraints.tfvars'])
  yaml_plan = plan_summary(
      'modules/organization', tf_var_files=['common.tfvars'],
      org_policy_custom_constraints_data_path=f'{tmp_path}')
  assert tfvars_plan.values == yaml_plan.values
