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

import yaml


def test_simple(generic_plan_validator):
  generic_plan_validator(inventory_path='psa_simple.yaml',
                         module_path="modules/net-vpc",
                         tf_var_files=['common.tfvars', 'psa_simple.tfvars'])


def test_routes_export(generic_plan_validator):
  generic_plan_validator(
      inventory_path='psa_routes_export.yaml', module_path="modules/net-vpc",
      tf_var_files=['common.tfvars', 'psa_routes_export.tfvars'])


def test_routes_import(generic_plan_validator):
  generic_plan_validator(
      inventory_path='psa_routes_import.yaml', module_path="modules/net-vpc",
      tf_var_files=['common.tfvars', 'psa_routes_import.tfvars'])


def test_routes_import_export(generic_plan_validator):
  generic_plan_validator(
      inventory_path='psa_routes_import_export.yaml',
      module_path="modules/net-vpc",
      tf_var_files=['common.tfvars', 'psa_routes_import_export.tfvars'])
