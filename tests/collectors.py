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

import pytest
import yaml

from .fixtures import generic_plan_summary, generic_plan_validator


class FabricTestFile(pytest.File):

  def collect(self):
    raw = yaml.safe_load(self.path.open())
    module = raw['module']
    for test_name, spec in raw['tests'].items():
      inventory = spec.get('inventory', f'{test_name}.yaml')
      tfvars = spec['tfvars']
      yield FabricTestItem.from_parent(self, name=test_name, module=module,
                                       inventory=inventory, tfvars=tfvars)


class FabricTestItem(pytest.Item):

  def __init__(self, name, parent, module, inventory, tfvars):
    super().__init__(name, parent)
    self.module = module
    self.inventory = inventory
    self.tfvars = tfvars

  def runtest(self):
    s = generic_plan_validator(self.module, self.inventory,
                               self.parent.path.parent, self.tfvars)

  def reportinfo(self):
    return self.path, None, self.name


def pytest_collect_file(parent, file_path):
  if file_path.suffix == '.yaml' and file_path.name.startswith('tftest'):
    return FabricTestFile.from_parent(parent, path=file_path)
