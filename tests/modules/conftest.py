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

import inspect
import pathlib

import hcl2
import pytest
import yaml


def pytest_collection_modifyitems(config, items):
  for item in items:
    item.add_marker(pytest.mark.xdist_group(name=item.path.parent.name))


@pytest.fixture(scope='session')
def tfvars_to_yaml():

  def converter(source, dest, from_var, to_var=None):
    p_fixture = pathlib.Path(inspect.stack()[1].filename).parent / 'fixture'
    p_source = p_fixture / source
    if not p_source.exists():
      raise ValueError(f"tfvars '{source}' not found")
    try:
      with p_source.open() as f:
        data = hcl2.load(f)
    except Exception as e:
      raise ValueError(f'error decoding tfvars: {e.args[0]}')
    if from_var not in data:
      raise ValueError(f"variable '{from_var}' not in tfvars")
    if to_var is None:
      data_yaml = data[from_var]
    else:
      data_yaml = {to_var: data[from_var]}
    p_dest = pathlib.Path(dest) if not isinstance(dest, pathlib.Path) else dest
    try:
      with p_dest.open('w') as f:
        data_yaml = yaml.dump(data_yaml, f)
    except yaml.YAMLError as e:
      raise ValueError(f'error encoding data to yaml: {e.args[0]}')
    except (IOError, OSError) as e:
      raise ValueError(f"error writing '{dest}': {e.args[0]}")

  return converter
