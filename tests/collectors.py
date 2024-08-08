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
"""Pytest plugin to discover tests specified in YAML files.

This plugin uses the pytest_collect_file hook to collect all files
matching tftest*.yaml and runs plan_validate for each test found.
See FabricTestFile for details on the file structure.

"""

import json
from pathlib import Path
import fnmatch

import jsonschema
import pytest
import yaml

from .examples.utils import get_tftest_directive
from .fixtures import plan_summary, plan_validator

_REPO_ROOT = Path(__file__).parents[1]


class FabricTestFile(pytest.File):

  def collect(self):
    """Read yaml test spec and yield test items for each test definition.

    The test spec should contain a `module` key with the path of the
    terraform module to test, relative to the root of the repository

    Tests are defined within the top-level `tests` key, and should
    have the following structure:

    test-name:
      extra_files:
        - bar.tf
        - foo.tf
      tfvars:
        - tfvars1.tfvars
        - tfvars2.tfvars
      inventory:
        - inventory1.yaml
        - inventory2.yaml

    All paths specifications are relative to the location of the test
    spec. The inventory key is optional, if omitted, the inventory
    will be taken from the file test-name.yaml

    """

    try:
      raw = yaml.safe_load(self.path.open())
      module = raw.pop('module')
    except (IOError, OSError, yaml.YAMLError) as e:
      raise Exception(f'cannot read test spec {self.path}: {e}')
    except KeyError as e:
      raise Exception(f'`module` key not found in {self.path}: {e}')
    common = raw.pop('common_tfvars', [])
    for test_name, spec in raw.get('tests', {}).items():
      spec = {} if spec is None else spec
      extra_files = spec.get('extra_files')
      inventories = spec.get('inventory', [f'{test_name}.yaml'])
      tf_var_files = common + [f'{test_name}.tfvars'] + spec.get('tfvars', [])
      for i in inventories:
        name = test_name
        if isinstance(inventories, list) and len(inventories) > 1:
          name = f'{test_name}[{i}]'
        yield FabricTestItem.from_parent(self, name=name, module=module,
                                         inventory=[i],
                                         tf_var_files=tf_var_files,
                                         extra_files=extra_files)


class FabricTestItem(pytest.Item):

  def __init__(self, name, parent, module, inventory, tf_var_files,
               extra_files=None):
    super().__init__(name, parent)
    self.module = module
    self.inventory = inventory
    self.tf_var_files = tf_var_files
    self.extra_files = extra_files

  def runtest(self):
    try:
      summary = plan_validator(self.module, self.inventory,
                               self.parent.path.parent, self.tf_var_files,
                               self.extra_files)
    except AssertionError:

      def full_paths(x):
        return [str(self.parent.path.parent / x) for x in x]

      print(f'Error in inventory file: {" ".join(full_paths(self.inventory))}')
      print(
          f'To regenerate inventory run: python tools/plan_summary.py {self.module} {" ".join(full_paths(self.tf_var_files))}'
      )
      raise

  def reportinfo(self):
    return self.path, None, self.name


class FabricSchemaTestFile(pytest.File):

  def collect(self):
    try:
      raw = self.path.read_text()
      content = yaml.safe_load(raw)
    except (IOError, OSError, yaml.YAMLError) as e:
      raise Exception(f'Cannot read test spec {self.path}: {e}')
    directive = get_tftest_directive(raw)
    if not directive or directive.name != 'tftest':
      raise Exception(f'Schema test file without tftest directive: {self.path}')
    name = str(self.path)
    yield FabricSchemaTestItem.from_parent(self, name=name, directive=directive,
                                           content=content)


class FabricSchemaTestItem(pytest.Item):

  def __init__(self, name, parent, directive, content):
    super().__init__(name, parent)
    self.directive = directive
    self.content = content

  def runtest(self):
    if 'schema' not in self.directive.kwargs:
      raise Exception(
          f'Schema test file does not declare schema: {self.parent.path}')
    schema_path = _REPO_ROOT / self.directive.kwargs['schema']
    schema = json.load(schema_path.open())
    if 'fail' in self.directive.args:
      with pytest.raises(jsonschema.exceptions.ValidationError):
        jsonschema.validate(instance=self.content, schema=schema)
    else:
      jsonschema.validate(instance=self.content, schema=schema)

  def reportinfo(self):
    return self.path, None, self.name


def pytest_collect_file(parent, file_path):
  'Collect tftest*.yaml files and run plan_validator from them.'
  if file_path.suffix == '.yaml' and file_path.name.startswith('tftest'):
    return FabricTestFile.from_parent(parent, path=file_path)

  # use fnmatch because Path.match doesn't support **
  file_path_relative = str(file_path.relative_to(_REPO_ROOT))
  if fnmatch.fnmatch(file_path_relative, "tests/schemas/**.yaml"):
    return FabricSchemaTestFile.from_parent(parent, path=file_path)
