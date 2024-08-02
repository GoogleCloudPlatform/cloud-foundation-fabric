# Copyright 2024 Google LLC
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
"""Common fixtures."""

import collections
import contextlib
import glob
import os
import shutil
import tempfile
import time
from pathlib import Path

import pytest
import tftest
import yaml

_REPO_ROOT = Path(__file__).parents[1]
PlanSummary = collections.namedtuple('PlanSummary', 'values counts outputs')


@contextlib.contextmanager
def _prepare_root_module(path):
  """Context manager to prepare a terraform module to be tested.

  `path` is copied to a temporary directory and a few terraform files
  (e.g. terraform.tfvars) are deleted to ensure a clean test
  environment.
  """
  # if we're copying the module, we might as well ignore files and
  # directories that are automatically read by terraform. Useful
  # to avoid surprises if, for example, you have an active fast
  # deployment with links to configs)
  ignore_patterns = shutil.ignore_patterns('*.auto.tfvars',
                                           '*.auto.tfvars.json',
                                           '[0-9]-*-providers.tf',
                                           'terraform.tfstate*',
                                           '.terraform.lock.hcl',
                                           'terraform.tfvars', '.terraform')

  with tempfile.TemporaryDirectory(dir=path.parent) as tmp_path:
    tmp_path = Path(tmp_path)

    # Running tests in a copy made with symlinks=True makes them run
    # ~20% slower than when run in a copy made with symlinks=False.
    shutil.copytree(path, tmp_path, dirs_exist_ok=True, symlinks=False,
                    ignore=ignore_patterns)
    lockfile = _REPO_ROOT / 'tools' / 'lockfile' / '.terraform.lock.hcl'
    if lockfile.exists():
      shutil.copy(lockfile, tmp_path / '.terraform.lock.hcl')

    yield tmp_path


def plan_summary(module_path, basedir, tf_var_files=None, extra_files=None,
                 **tf_vars):
  """
  Run a Terraform plan on the module located at `module_path`.

  - module_path: terraform root module to run. Can be an absolute
    path or relative to the root of the repository

  - basedir: directory root to use for relative paths in
    tf_var_files.

  - tf_var_files: set of terraform variable files (tfvars) to pass
    in to terraform

  - extra_files: set of extra files to optionally pass
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
  # make the module_path relative to the root of the repo while still
  # supporting absolute paths
  module_path = _REPO_ROOT / module_path
  with _prepare_root_module(module_path) as test_path:
    binary = os.environ.get('TERRAFORM', 'terraform')
    tf = tftest.TerraformTest(test_path, binary=binary)
    extra_files = [(module_path / filename).resolve()
                   for x in extra_files or []
                   for filename in glob.glob(x, root_dir=module_path)]
    tf.setup(extra_files=extra_files, upgrade=True)
    tf_var_files = [(basedir / x).resolve() for x in tf_var_files or []]
    plan = tf.plan(output=True, tf_var_file=tf_var_files, tf_vars=tf_vars)

    # compute resource type counts and address->values map
    values = {}
    counts = collections.defaultdict(int)
    counts['modules'] = counts['resources'] = 0
    q = collections.deque([plan.root_module])
    while q:
      e = q.popleft()
      if 'type' in e:
        counts[e['type']] += 1
      if 'values' in e:
        values[e['address']] = e['values']
      for x in e.get('resources', []):
        counts['resources'] += 1
        q.append(x)
      for x in e.get('child_modules', []):
        counts['modules'] += 1
        q.append(x)

    # extract planned outputs
    outputs = plan.get('planned_values', {}).get('outputs', {})

    # force the destruction of the tftest object, otherwise pytest
    # will complain about unraisable exceptions caused by the context
    # manager deleting temporary files, including the extra_files that
    # tftest tries to remove on cleanup
    del tf

    return PlanSummary(values, dict(counts), outputs)


@pytest.fixture(name='plan_summary')
def plan_summary_fixture(request):
  """Return a function to generate a PlanSummary.

  In the returned function `basedir` becomes optional and it defaults
  to the directory of the calling test
  """

  def inner(module_path, basedir=None, tf_var_files=None, extra_files=None,
            **tf_vars):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return plan_summary(module_path=module_path, basedir=basedir,
                        tf_var_files=tf_var_files, extra_files=extra_files,
                        **tf_vars)

  return inner


def plan_validator(module_path, inventory_paths, basedir, tf_var_files=None,
                   extra_files=None, **tf_vars):
  summary = plan_summary(module_path=module_path, tf_var_files=tf_var_files,
                         extra_files=extra_files, basedir=basedir, **tf_vars)

  # allow single single string for inventory_paths
  if not isinstance(inventory_paths, list):
    inventory_paths = [inventory_paths]

  for path in inventory_paths:
    # allow tfvars and inventory to be relative to the caller
    path = basedir / path
    relative_path = path.relative_to(_REPO_ROOT)
    try:
      inventory = yaml.safe_load(path.read_text())
    except (IOError, OSError, yaml.YAMLError) as e:
      raise Exception(f'cannot read test inventory {path}: {e}')

    # don't fail if the inventory is empty
    inventory = inventory or {}

    # If you add additional asserts to this function:
    # - put the values coming from the plan on the left side of
    #   any comparison operators
    # - put the values coming from user's inventory the right
    #   side of any comparison operators.
    # - include a descriptive error message to the assert
    # print(yaml.dump({'values': summary.values}))
    # print(yaml.dump({'counts': summary.counts}))

    if 'values' in inventory:
      try:
        validate_plan_object(inventory['values'], summary.values, relative_path,
                             "")
      except AssertionError:
        print(f'\n{path}')
        print(yaml.dump({'values': summary.values}))
        raise

    if 'counts' in inventory:
      try:
        expected_counts = inventory['counts']
        for type_, expected_count in expected_counts.items():
          assert type_ in summary.counts, \
              f'{relative_path}: module does not create any resources of type `{type_}`'
          plan_count = summary.counts[type_]
          assert plan_count == expected_count, \
              f'{relative_path}: count of {type_} resources failed. Got {plan_count}, expected {expected_count}'
      except AssertionError:
        print(f'\n{path}')
        print(yaml.dump({'counts': summary.counts}))
        raise

    if 'outputs' in inventory:
      _buffer = None
      try:
        expected_outputs = inventory['outputs']
        for output_name, expected_output in expected_outputs.items():
          assert output_name in summary.outputs, \
              f'{relative_path}: module does not output `{output_name}`'
          output = summary.outputs[output_name]
          # assert 'value' in output, \
          #   f'output `{output_name}` does not have a value (is it sensitive or dynamic?)'
          plan_output = output.get('value', '__missing__')
          _buffer = {output_name: plan_output}
          assert plan_output == expected_output, \
              f'{relative_path}: output {output_name} failed. Got `{plan_output}`, expected `{expected_output}`'
      except AssertionError:
        if _buffer:
          print(f'\n{path}')
          print(yaml.dump(_buffer))
        raise
  return summary


def validate_plan_object(expected_value, plan_value, relative_path,
                         relative_address):
  """
  Validate that plan object matches inventory

  1. Verify each address in the user's inventory exists in the plan
  2. For those address that exist on both the user's inventory and
     the plan output, ensure the set of keys on the inventory are a
     subset of the keys in the plan, and compare their values by
     equality
  3. For lists, verify that they have the same length and check
     whether its members are equal (according to this function)
  """
  # dictionaries / objects
  if isinstance(expected_value, dict) and isinstance(plan_value, dict):
    for k, v in expected_value.items():
      assert k in plan_value, \
        f'{relative_path}: {relative_address}.{k} is not a valid address in the plan'
      validate_plan_object(v, plan_value[k], relative_path,
                           f'{relative_address}.{k}')

  # lists
  elif isinstance(expected_value, list) and isinstance(plan_value, list):
    assert len(plan_value) == len(expected_value), \
      f'{relative_path}: {relative_address} has different length. Got {plan_value}, expected {expected_value}'

    for i, (exp, actual) in enumerate(zip(expected_value, plan_value)):
      validate_plan_object(exp, actual, relative_path,
                           f'{relative_address}[{i}]')

  # all other objects
  else:
    assert plan_value == expected_value, \
      f'{relative_path}: {relative_address} failed. Got `{plan_value}`, expected `{expected_value}`'


@pytest.fixture(name='plan_validator')
def plan_validator_fixture(request):
  """Return a function to build a PlanSummary and compare it to a YAML inventory.

  In the returned function `basedir` becomes optional and it defaults
  to the directory of the calling test'

  """

  def inner(module_path, inventory_paths, basedir=None, tf_var_files=None,
            **tf_vars):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return plan_validator(module_path=module_path,
                          inventory_paths=inventory_paths, basedir=basedir,
                          tf_var_files=tf_var_files, **tf_vars)

  return inner


def get_tfvars_for_e2e():
  _variables = [
      'billing_account', 'group_email', 'organization_id', 'parent', 'prefix',
      'region', 'region_secondary'
  ]
  missing_vars = set([f'TFTEST_E2E_{k}' for k in _variables]) - set(
      os.environ.keys())
  if missing_vars:
    raise RuntimeError(
        f'Missing environment variables: {missing_vars} required to run E2E tests. '
        f'Consult CONTRIBUTING.md to understand how to set them up. '
        f'If you want to skip E2E tests add -k "not examples_e2e" to your pytest call'
    )
  tf_vars = {k: os.environ.get(f'TFTEST_E2E_{k}') for k in _variables}
  if tf_vars['region'] == tf_vars['region_secondary']:
    raise ValueError(
        "E2E tests require distinct primary and secondary regions.")
  return tf_vars


def e2e_validator(module_path, extra_files, tf_var_files, basedir=None):
  """Function running apply, plan and destroy to verify the case end to end

  1. Tests whether apply does not return errors
  2. Tests whether plan after apply is empty
  3. Tests whether destroy does not return errors
  """
  module_path = _REPO_ROOT / module_path
  with _prepare_root_module(module_path) as test_path:
    binary = os.environ.get('TERRAFORM', 'terraform')
    tf = tftest.TerraformTest(test_path, binary=binary)
    extra_files = [(module_path / filename).resolve()
                   for x in extra_files or []
                   for filename in glob.glob(x, root_dir=module_path)]
    tf.setup(extra_files=extra_files, upgrade=True)
    tf_var_files = [(basedir / x).resolve() for x in tf_var_files or []]

    # we need only prefix variable to run the example test, all the other are passed in terraform.tfvars file
    prefix = get_tfvars_for_e2e()["prefix"]
    # to allow different tests to create projects (or other globally unique resources) with the same name
    # bump prefix forward on each test execution
    tf_vars = {
        "prefix":
            f'{prefix}-{int(time.time())}{os.environ.get("PYTEST_XDIST_WORKER", "0")[-2:]}'
    }
    try:
      apply = tf.apply(tf_var_file=tf_var_files, tf_vars=tf_vars)
      plan = tf.plan(output=True, tf_var_file=tf_var_files, tf_vars=tf_vars)
      changes = {}
      for resource_name, value in plan.resource_changes.items():
        if value.get('change', {}).get('actions') != ['no-op']:
          changes[resource_name] = value['change']

      # compare before with after to raise more meaningful failure to the user, i.e one
      # that shows how resource will change
      plan_before_state = {k: v.get('before') for k, v in changes.items()}
      plan_after_state = {k: v.get('after') for k, v in changes.items()}

      assert plan_before_state == plan_after_state, f'Plan not empty after apply for values'

      plan_before_sensitive_state = {
          k: v.get('before_sensitive') for k, v in changes.items()
      }
      plan_after_sensitive_state = {
          k: v.get('after_sensitive') for k, v in changes.items()
      }
      assert plan_before_sensitive_state == plan_after_sensitive_state, f'Plan not empty after apply for sensitive values'

      # If above did not fail, this should not either, but left as a safety check
      assert changes == {}, f'Plan not empty for following resources: {", ".join(changes.keys())}'
    finally:
      destroy = tf.destroy(tf_var_file=tf_var_files, tf_vars=tf_vars)


@pytest.fixture(name='e2e_validator')
def e2e_validator_fixture(request):
  """Return a function to run end-to-end test

  In the returned function `basedir` becomes optional and it defaults
  to the directory of the calling test

  """

  def inner(module_path: str, extra_files: list, tf_var_files: list,
            basedir: os.PathLike = None):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return e2e_validator(module_path, extra_files, tf_var_files, basedir)

  return inner


@pytest.fixture(scope='session', name='e2e_tfvars_path')
def e2e_tfvars_path():
  """Fixture preparing end-to-end test environment

  If TFTEST_E2E_TFVARS_PATH is set in the environment, then assume the environment is already provisioned
  and necessary variables are set in the file to which variable is pointing to.

  Otherwise, create a unique test environment (in case of multiple workers - as many environments as
  there are workers), that will be injected into each example test instead of `tests/examples/variables.tf`.

  Returns path to tfvars file that contains information about environment to use for the tests.
  """
  if tfvars_path := os.environ.get('TFTEST_E2E_TFVARS_PATH'):
    # no need to set up the project
    if int(os.environ.get('PYTEST_XDIST_WORKER_COUNT', '0')) > 1:
      raise RuntimeError(
          'Setting TFTEST_E2E_TFVARS_PATH is not compatible with running tests in parallel'
      )
    yield tfvars_path
  else:
    with _prepare_root_module(_REPO_ROOT / 'tests' / 'examples_e2e' /
                              'setup_module') as test_path:
      binary = os.environ.get('TERRAFORM', 'terraform')
      tf = tftest.TerraformTest(test_path, binary=binary)
      tf_vars_file = None
      tf_vars = get_tfvars_for_e2e()
      tf_vars['suffix'] = os.environ.get(
          "PYTEST_XDIST_WORKER",
          "0")[-2:]  # take at most 2 last chars for suffix
      tf_vars['timestamp'] = str(int(time.time()))

      if 'TFTEST_E2E_SETUP_TFVARS_PATH' in os.environ:
        tf_vars_file = os.environ["TFTEST_E2E_SETUP_TFVARS_PATH"]
      tf.setup(upgrade=True)
      tf.apply(tf_vars=tf_vars, tf_var_file=tf_vars_file)
      yield test_path / "e2e_tests.tfvars"
      tf.destroy(tf_vars=tf_vars, tf_var_file=tf_vars_file)


# @pytest.fixture
# def repo_root():
#   'Return a pathlib.Path to the root of the repository'
#   return Path(__file__).parents[1]
