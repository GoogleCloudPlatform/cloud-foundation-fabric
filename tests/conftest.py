# Copyright 2020 Google LLC
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

"Shared fixtures"

import os
import pytest
import tftest


BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def e2e_plan_runner(plan_runner):
  "Returns a function to run Terraform plan on an end-to-end fixture."

  def run_plan(fixture_path, targets=None):
    "Runs Terraform plan on an end-to-end module using defaults, returns data."
    _, modules = plan_runner(fixture_path, is_module=False, targets=targets)
    resources = [r for m in modules.values() for r in m]
    return modules, resources

  return run_plan


@pytest.fixture(scope='session')
def plan_runner():
  "Returns a function to run Terraform plan on a fixture."

  def run_plan(fixture_path, is_module=True, targets=None, **tf_vars):
    "Runs Terraform plan and returns parsed output"
    tf = tftest.TerraformTest(fixture_path, BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup()
    plan = tf.plan(output=True, tf_vars=tf_vars, targets=targets)
    root_module = plan.planned_values['root_module']['child_modules'][0]
    if is_module:
      return (plan, root_module['resources'])
    modules = dict((mod['address'], mod['resources'])
                   for mod in root_module['child_modules'])
    return plan, modules

  return run_plan


@pytest.fixture(scope='session')
def example_plan_runner():
  "Returns a function to run Terraform plan on an example."

  def run_plan(fixture_path, is_module=True, targets=None, **tf_vars):
    "Runs Terraform plan and returns parsed output"
    tf = tftest.TerraformTest(fixture_path, BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup()
    plan = tf.plan(output=True, tf_vars=tf_vars, targets=targets)
    modules = plan.modules
    resources = []
    for name, module in modules.items():
      for _, resource in module.resources.items():
        resources.append(resource)
    return plan, modules, resources

  return run_plan


@pytest.fixture(scope='session')
def apply_runner():
  "Returns a function to run Terraform apply on a fixture."

  def run_apply(fixture_path, **tf_vars):
    "Runs Terraform apply and returns parsed output"
    tf = tftest.TerraformTest(fixture_path, BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup()
    apply = tf.apply(tf_vars=tf_vars)
    output = tf.output(json_format=True)
    return apply, output

  return run_apply
