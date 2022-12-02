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
'Shared fixtures.'

import collections
import inspect
import itertools
import os
import shutil
import tempfile
from pathlib import Path

import pytest
import tftest
import yaml

PlanSummary = collections.namedtuple('PlanSummary', 'values counts outputs')

BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def _plan_runner():
  'Return a function to run Terraform plan on a fixture.'

  def run_plan(fixture_path=None, extra_files=None, tf_var_file=None,
               targets=None, refresh=True, tmpdir=True, **tf_vars):
    'Run Terraform plan and returns parsed output.'
    if fixture_path is None:
      # find out the fixture directory from the caller's directory
      caller = inspect.stack()[2]
      fixture_path = os.path.join(os.path.dirname(caller.filename), 'fixture')

    fixture_parent = os.path.dirname(fixture_path)
    fixture_prefix = os.path.basename(fixture_path) + '_'
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
  'Return a function to run Terraform plan on a module fixture.'

  def run_plan(fixture_path=None, extra_files=None, tf_var_file=None,
               targets=None, **tf_vars):
    'Run Terraform plan and returns plan and module resources.'
    plan = _plan_runner(fixture_path, extra_files=extra_files,
                        tf_var_file=tf_var_file, targets=targets, **tf_vars)
    # skip the fixture
    root_module = plan.root_module['child_modules'][0]
    return plan, root_module['resources']

  return run_plan


@pytest.fixture(scope='session')
def e2e_plan_runner(_plan_runner):
  'Return a function to run Terraform plan on an end-to-end fixture.'

  def run_plan(fixture_path=None, tf_var_file=None, targets=None, refresh=True,
               include_bare_resources=False, **tf_vars):
    'Run Terraform plan on an end-to-end module using defaults, returns data.'
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
  """
  Plan runner for end-to-end root module, returns total number of
  (nested) modules and resources
  """

  def walk_plan(node, modules, resources):
    new_modules = node.get('child_modules', [])
    resources += node.get('resources', [])
    modules += new_modules
    for module in new_modules:
      walk_plan(module, modules, resources)

  def run_plan(fixture_path=None, tf_var_file=None, targets=None, refresh=True,
               include_bare_resources=False, compute_sums=True, tmpdir=True,
               **tf_vars):
    'Run Terraform plan on a root module using defaults, returns data.'
    plan = _plan_runner(fixture_path, tf_var_file=tf_var_file, targets=targets,
                        refresh=refresh, tmpdir=tmpdir, **tf_vars)
    modules = []
    resources = []
    walk_plan(plan.root_module, modules, resources)
    return len(modules), len(resources)

  return run_plan


@pytest.fixture(scope='session')
def apply_runner():
  'Return a function to run Terraform apply on a fixture.'

  def run_apply(fixture_path=None, **tf_vars):
    'Run Terraform plan and returns parsed output.'
    if fixture_path is None:
      # find out the fixture directory from the caller's directory
      caller = inspect.stack()[1]
      fixture_path = os.path.join(os.path.dirname(caller.filename), 'fixture')

    fixture_parent = os.path.dirname(fixture_path)
    fixture_prefix = os.path.basename(fixture_path) + '_'

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


def _generic_plan_summary(module_path, basedir, tf_var_files=None, **tf_vars):
  """
  Run a Terraform plan on the module located at `module_path`.

  - module_path: terraform root module to run. Can be an absolute
    path or relative to the root of the repository

  - basedir: directory root to use for relative paths in
    tf_var_files. 

  - tf_var_files: set of terraform variable files (tfvars) to pass
    in to terraform

  Returns a PlanSummary object containing 3 attributes:
  - values: dictionary where the keys are terraform plan addresses
    and values are the JSON representation (converted to python
    types) of the attribute values of the resource. 

  - counts: dictionary where the keys are the terraform resource
    types and the values are the number of times that type appears
    in the plan

  - outputs: dictionary of the modules outputs that can be
    determined at plan type. 

  Consult [1] for mode details on the structure of values and outputs

  [1] https://developer.hashicorp.com/terraform/internals/json-format
  """
  module_path = Path(BASEDIR) / module_path

  # FIXME: find a way to prevent the temp dir if TFTEST_COPY is not
  # in the environment
  with tempfile.TemporaryDirectory(dir=module_path.parent) as tmp_path:
    # if TFTEST_COPY is set, copy the fixture to a temporary
    # directory before running the plan. This is needed if you want
    # to run multiple tests for the same module in parallel
    if os.environ.get('TFTEST_COPY'):
      test_path = Path(tmp_path)
      shutil.copytree(module_path, test_path, dirs_exist_ok=True)

      # if we're copying the module, we might as well remove any files
      # and directories from the test directory that are automatically
      # read by terraform. Useful to avoid surprises if, for example,
      # you have an active fast deployment with links to configs)
      autopaths = itertools.chain(
          test_path.glob('*.auto.tfvars'),
          test_path.glob('*.auto.tfvars.json'),
          test_path.glob('terraform.tfstate*'),
          test_path.glob('terraform.tfvars'),
          test_path.glob('.terraform'),
          # any symlinks?
      )
      for p in autopaths:
        if p.is_dir():
          shutil.rmtree(p)
        else:
          p.unlink()
    else:
      test_path = module_path

    # prepare tftest and run plan
    binary = os.environ.get('TERRAFORM', 'terraform')
    tf = tftest.TerraformTest(test_path, binary=binary)
    tf.setup(upgrade=True)
    tf_var_files = [(basedir / x).resolve() for x in tf_var_files or []]
    plan = tf.plan(output=True, refresh=True, tf_var_file=tf_var_files,
                   tf_vars=tf_vars)

    # compute resource type counts and address->values map
    values = {}
    counts = collections.defaultdict(int)
    q = collections.deque([plan.root_module])
    while q:
      e = q.popleft()

      if 'type' in e:
        counts[e['type']] += 1
      if 'values' in e:
        values[e['address']] = e['values']

      for x in e.get('resources', []):
        q.append(x)
      for x in e.get('child_modules', []):
        q.append(x)

    # extract planned outputs
    outputs = plan.get('planned_values', {}).get('outputs', {})

    return PlanSummary(values, dict(counts), outputs)


@pytest.fixture
def generic_plan_summary(request):
  'Return a function to generate a PlanSummary.'

  def inner(module_path, basedir=None, tf_var_files=None, **tf_vars):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return _generic_plan_summary(module_path=module_path, basedir=basedir,
                                 tf_var_files=tf_var_files, **tf_vars)

  return inner


def _generic_plan_validator(module_path, inventory_paths, basedir,
                            tf_var_files=None, **tf_vars):
  summary = _generic_plan_summary(module_path=module_path,
                                  tf_var_files=tf_var_files, basedir=basedir,
                                  **tf_vars)

  # allow single single string for inventory_paths
  if not isinstance(inventory_paths, list):
    inventory_paths = [inventory_paths]

  for path in inventory_paths:
    # allow tfvars and inventory to be relative to the caller
    path = basedir / path
    inventory = yaml.safe_load(path.read_text())
    assert inventory is not None, f'Inventory {path} is empty'

    # If you add additional asserts to this function:
    # - put the values coming from the plan on the left side of
    #   any comparison operators
    # - put the values coming from user's inventory the right
    #   side of any comparison operators.
    # - include a descriptive error message to the assert

    # for values:
    # - verify each address in the user's inventory exists in the plan
    # - for those address that exist on both the user's inventory and
    #   the plan output, ensure the set of keys on the inventory are a
    #   subset of the keys in the plan, and compare their values by
    #   equality
    if 'values' in inventory:
      expected_values = inventory['values']
      for address, expected_value in expected_values.items():
        assert address in summary.values, \
          f'{address} is not a valid address in the plan'
        for k, v in expected_value.items():
          assert k in summary.values[address], \
            f'{k} not found at {address}'
          plan_value = summary.values[address][k]
          assert plan_value == v, \
            f'{k} at {address} failed. Got `{plan_value}`, expected `{v}`'

    if 'counts' in inventory:
      expected_counts = inventory['counts']
      for type_, expected_count in expected_counts.items():
        assert type_ in summary.counts, \
          f'module does not create any resources of type `{type_}`'
        plan_count = summary.counts[type_]
        assert plan_count == expected_count, \
            f'count of {type_} resources failed. Got {plan_count}, expected {expected_count}'

    if 'outputs' in inventory:
      expected_outputs = inventory['outputs']
      for output_name, expected_output in expected_outputs.items():
        assert output_name in summary.outputs, \
          f'module does not output `{output_name}`'
        output = summary.outputs[output_name]
        # assert 'value' in output, \
        #   f'output `{output_name}` does not have a value (is it sensitive or dynamic?)'
        plan_output = output.get('value', '__missing__')
        assert plan_output == expected_output, \
            f'output {output_name} failed. Got `{plan_output}`, expected `{expected_output}`'

  return summary


@pytest.fixture
def generic_plan_validator(request):
  'Return a function that builds a PlanSummary and compares it to an yaml inventory.'

  def inner(module_path, inventory_paths, basedir=None, tf_var_files=None,
            **tf_vars):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return _generic_plan_validator(module_path=module_path,
                                   inventory_paths=inventory_paths,
                                   basedir=basedir, tf_var_files=tf_var_paths,
                                   **tf_vars)

  return inner


def pytest_collect_file(parent, file_path):
  if file_path.suffix == '.yaml' and file_path.name.startswith('tftest'):
    return FabricTestFile.from_parent(parent, path=file_path)


class FabricTestFile(pytest.File):

  def collect(self):
    raw = yaml.safe_load(self.path.open())
    module = raw['module']
    for test_name, spec in raw['tests'].items():
      inventory = spec.get('inventory', f'{test_name}.yaml')
      tfvars = spec['tfvars']
      yield FabricTestItem.from_parent(self, name=test_name, module=module,
                                       inventory=inventory, tfvars=tfvars)


from icecream import ic


class FabricTestItem(pytest.Item):

  def __init__(self, name, parent, module, inventory, tfvars):
    super().__init__(name, parent)
    self.module = module
    self.inventory = inventory
    self.tfvars = tfvars

  def runtest(self):
    s = _generic_plan_validator(self.module, self.inventory,
                                self.parent.path.parent, self.tfvars)

  def reportinfo(self):
    return self.path, None, self.name
