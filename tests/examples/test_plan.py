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

import re
import subprocess
import yaml
import shutil
import tempfile
from pathlib import Path

BASE_PATH = Path(__file__).parent
COUNT_TEST_RE = re.compile(
    r'# tftest +modules=(?P<modules>\d+) +resources=(?P<resources>\d+)' +
    r'(?: +files=(?P<files>[\w@,_-]+))?' +
    r'(?: +fixtures=(?P<fixtures>[\w@,_/.-]+))?' +
    r'(?: +inventory=(?P<inventory>[\w\-.]+))?')


def prepare_files(example, test_path, files, fixtures):
  if files is not None:
    requested_files = files.split(',')
    for f in requested_files:
      destination = test_path / example.files[f].path
      destination.parent.mkdir(parents=True, exist_ok=True)
      destination.write_text(example.files[f].content)

  if fixtures is not None:
    requested_fixtures = fixtures.split(',')
    for f in requested_fixtures:
      if f.startswith('fixtures/'):
        # fixture is specified referencing a global fixture in (tests/fixtures/)
        source = BASE_PATH.parent / f
        destination = test_path / source.name
        destination.symlink_to(source)
      else:
        # fixture is specified using an inline tftest-fixture tag
        destination = test_path / f'{f}.tf'
        destination.write_text(example.fixtures[f])


def test_example(plan_validator, example):
  if match := COUNT_TEST_RE.search(example.code):
    # for tfvars-based tests, create the temporary directory with the
    # same parent as the original module
    directory = example.module.parent if example.type == 'tfvars' else None
    prefix = f'pytest-{example.module.name}'
    with tempfile.TemporaryDirectory(prefix=prefix, dir=directory) as tmp_path:
      tmp_path = Path(tmp_path)
      tf_var_files = []
      if example.type == 'hcl':
        (tmp_path / 'fabric').symlink_to(BASE_PATH.parents[1])
        (tmp_path / 'variables.tf').symlink_to(BASE_PATH / 'variables.tf')
        (tmp_path / 'main.tf').write_text(example.code)
        assets_path = (BASE_PATH.parent /
                       str(example.module).replace('-', '_') / 'assets')
        if assets_path.exists():
          (tmp_path / 'assets').symlink_to(assets_path)

        prepare_files(example, tmp_path, match.group('files'),
                      match.group('fixtures'))
      elif example.type == 'tfvars':
        (tmp_path / 'terraform.auto.tfvars').write_text(example.code)
        shutil.copytree(example.module, tmp_path, dirs_exist_ok=True)
        tf_var_files = [(tmp_path / 'terraform.auto.tfvars').resolve()]

      expected_modules = int(match.group('modules'))
      expected_resources = int(match.group('resources'))

      inventory = []
      if match.group('inventory') is not None:
        python_test_path = str(example.module).replace('-', '_')
        inventory = BASE_PATH.parent / python_test_path / 'examples'
        inventory = inventory / match.group('inventory')

      summary = plan_validator(module_path=tmp_path, inventory_paths=inventory,
                               tf_var_files=tf_var_files)

      print('\n')
      print(yaml.dump({'values': summary.values}))
      print(yaml.dump({'counts': summary.counts}))
      print(yaml.dump({'outputs': summary.outputs}))

      counts = summary.counts
      num_modules, num_resources = counts['modules'], counts['resources']
      assert expected_modules == num_modules, 'wrong number of modules'
      assert expected_resources == num_resources, 'wrong number of resources'

      # TODO(jccb): this should probably be done in check_documentation
      # but we already have all the data here.
      result = subprocess.run(
          'terraform fmt -check -diff -no-color main.tf'.split(), cwd=tmp_path,
          stdout=subprocess.PIPE, encoding='utf-8')
      assert result.returncode == 0, f'terraform code not formatted correctly\n{result.stdout}'

  else:
    assert False, "can't find tftest directive"
