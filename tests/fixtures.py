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
"""Common fixtures."""

import collections
import contextlib
import itertools
import os
import shutil
import tempfile
from pathlib import Path

import pytest
import tftest
import yaml

PlanSummary = collections.namedtuple('PlanSummary', 'values counts outputs')


@contextlib.contextmanager
def _prepare_root_module(path):
  """Context manager to prepare a terraform module to be tested.
  
  If the TFTEST_COPY environment variable is set, `path` is copied to
  a temporary directory and a few terraform files (e.g.
  terraform.tfvars) are delete to ensure a clean test environment.
  Otherwise, `path` is simply returned untouched.
  """
  if os.environ.get('TFTEST_COPY'):
    # if the TFTEST_COPY is set, create temp dir and copy the root
    # module there
    with tempfile.TemporaryDirectory(dir=path.parent) as tmp_path:
      tmp_path = Path(tmp_path)

      # if we're copying the module, we might as well ignore files and
      # directories that are automatically read by terraform. Useful
      # to avoid surprises if, for example, you have an active fast
      # deployment with links to configs)
      ignore_patterns = shutil.ignore_patterns('*.auto.tfvars',
                                               '*.auto.tfvars.json',
                                               'terraform.tfstate*',
                                               'terraform.tfvars', '.terraform')

      shutil.copytree(path, tmp_path, dirs_exist_ok=True,
                      ignore=ignore_patterns)

      yield tmp_path
  else:
    # if TFTEST_COPY is not set, just return the same path
    yield path


def plan_summary(module_path, basedir, tf_var_files=None, **tf_vars):
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
  # make the module_path relative to the root of the repo while still
  # supporting absolute paths
  module_path = Path(__file__).parents[1] / module_path
  with _prepare_root_module(module_path) as test_path:
    binary = os.environ.get('TERRAFORM', 'terraform')
    tf = tftest.TerraformTest(test_path, binary=binary)
    tf.setup(upgrade=True)
    tf_var_files = [(basedir / x).resolve() for x in tf_var_files or []]
    plan = tf.plan(output=True, tf_var_file=tf_var_files, tf_vars=tf_vars)

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


@pytest.fixture(name='plan_summary')
def plan_summary_fixture(request):
  """Return a function to generate a PlanSummary.

  In the returned function `basedir` becomes optional and it defaults
  to the directory of the calling test
  """

  def inner(module_path, basedir=None, tf_var_files=None, **tf_vars):
    if basedir is None:
      basedir = Path(request.fspath).parent
    return plan_summary(module_path=module_path, basedir=basedir,
                        tf_var_files=tf_var_files, **tf_vars)

  return inner


def plan_validator(module_path, inventory_paths, basedir, tf_var_files=None,
                   **tf_vars):
  summary = plan_summary(module_path=module_path, tf_var_files=tf_var_files,
                         basedir=basedir, **tf_vars)

  # allow single single string for inventory_paths
  if not isinstance(inventory_paths, list):
    inventory_paths = [inventory_paths]

  for path in inventory_paths:
    # allow tfvars and inventory to be relative to the caller
    path = basedir / path
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
                          tf_var_files=tf_var_paths, **tf_vars)

  return inner


# @pytest.fixture
# def repo_root():
#   'Return a pathlib.Path to the root of the repository'
#   return Path(__file__).parents[1]
