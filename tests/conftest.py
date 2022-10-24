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
"Shared fixtures"

import inspect
import os
import shutil
import tempfile

import pytest
import tftest

BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def _plan_runner():
  "Returns a function to run Terraform plan on a fixture."

  def run_plan(fixture_path=None, extra_files=None, tf_var_file=None,
               targets=None, refresh=True, tmpdir=True, **tf_vars):
    "Runs Terraform plan and returns parsed output."
    if fixture_path is None:
      # find out the fixture directory from the caller's directory
      caller = inspect.stack()[2]
      fixture_path = os.path.join(os.path.dirname(caller.filename), "fixture")

    fixture_parent = os.path.dirname(fixture_path)
    fixture_prefix = os.path.basename(fixture_path) + "_"
    with tempfile.TemporaryDirectory(prefix=fixture_prefix,
                                     dir=fixture_parent) as tmp_path:
      # copy fixture to a temporary directory so we can execute
      # multiple tests in parallel
      if tmpdir:
        shutil.copytree(fixture_path, tmp_path, dirs_exist_ok=True)
      tf = tftest.TerraformTest(tmp_path if tmpdir else fixture_path, BASEDIR,
                                os.environ.get('TERRAFORM', 'terraform'))
      tf.setup(extra_files=extra_files, upgrade=True)
      plan = tf.plan(output=True, refresh=refresh, tf_var_file=tf_var_file,
                     tf_vars=tf_vars, targets=targets)
    return plan

  return run_plan


@pytest.fixture(scope='session')
def plan_runner(_plan_runner):
  "Returns a function to run Terraform plan on a module fixture."

  def run_plan(fixture_path=None, extra_files=None, tf_var_file=None,
               targets=None, **tf_vars):
    "Runs Terraform plan and returns plan and module resources."
    plan = _plan_runner(fixture_path, extra_files=extra_files,
                        tf_var_file=tf_var_file, targets=targets, **tf_vars)
    # skip the fixture
    root_module = plan.root_module['child_modules'][0]
    return plan, root_module['resources']

  return run_plan


@pytest.fixture(scope='session')
def e2e_plan_runner(_plan_runner):
  "Returns a function to run Terraform plan on an end-to-end fixture."

  def run_plan(fixture_path=None, tf_var_file=None, targets=None, 
               refresh=True, include_bare_resources=False, **tf_vars):
    "Runs Terraform plan on an end-to-end module using defaults, returns data."
    plan = _plan_runner(fixture_path, tf_var_file=tf_var_file, targets=targets, 
                        refresh=refresh, **tf_vars)
    # skip the fixture
    root_module = plan.root_module['child_modules'][0]
    modules = dict((mod['address'], mod['resources'])
                   for mod in root_module['child_modules'])
    resources = [r for m in modules.values() for r in m]
    if include_bare_resources:
      bare_resources = root_module['resources']
      resources.extend(bare_resources)
    return modules, resources

  return run_plan


@pytest.fixture(scope='session')
def recursive_e2e_plan_runner(_plan_runner):
  """Plan runner for end-to-end root module, returns total number of
  (nested) modules and resources"""

  def walk_plan(node, modules, resources):
    # TODO(jccb): this would be better with node.get() but
    # TerraformPlanOutput objects don't have it
    new_modules = node.get('child_modules', [])
    resources += node.get('resources', [])
    modules += new_modules
    for module in new_modules:
      walk_plan(module, modules, resources)

  def run_plan(fixture_path=None, tf_var_file=None, targets=None, refresh=True,
               include_bare_resources=False, compute_sums=True, tmpdir=True,
               **tf_vars):
    "Runs Terraform plan on a root module using defaults, returns data."
    plan = _plan_runner(fixture_path, tf_var_file=tf_var_file, targets=targets, 
                        refresh=refresh, tmpdir=tmpdir, **tf_vars)
    modules = []
    resources = []
    walk_plan(plan.root_module, modules, resources)
    return len(modules), len(resources)

  return run_plan


@pytest.fixture(scope='session')
def apply_runner():
  "Returns a function to run Terraform apply on a fixture."

  def run_apply(fixture_path=None, **tf_vars):
    "Runs Terraform plan and returns parsed output."
    if fixture_path is None:
      # find out the fixture directory from the caller's directory
      caller = inspect.stack()[1]
      fixture_path = os.path.join(os.path.dirname(caller.filename), "fixture")

    fixture_parent = os.path.dirname(fixture_path)
    fixture_prefix = os.path.basename(fixture_path) + "_"

    with tempfile.TemporaryDirectory(prefix=fixture_prefix,
                                     dir=fixture_parent) as tmp_path:
      # copy fixture to a temporary directory so we can execute
      # multiple tests in parallel
      shutil.copytree(fixture_path, tmp_path, dirs_exist_ok=True)
      tf = tftest.TerraformTest(tmp_path, BASEDIR,
                                os.environ.get('TERRAFORM', 'terraform'))
      tf.setup(upgrade=True)
      apply = tf.apply(tf_vars=tf_vars)
      output = tf.output(json_format=True)
      return apply, output

  return run_apply


@pytest.fixture
def basedir():
  return BASEDIR
