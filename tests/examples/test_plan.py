# Copyright 2023 Google LLC
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
from pathlib import Path

BASE_PATH = Path(__file__).parent
COUNT_TEST_RE = re.compile(r'# tftest +modules=(\d+) +resources=(\d+)' +
                           r'(?: +files=([\w@,_-]+))?' +
                           r'(?: +inventory=([\w\-.]+))?')


def test_example(plan_validator, tmp_path, example):
  if match := COUNT_TEST_RE.search(example.code):
    (tmp_path / 'fabric').symlink_to(BASE_PATH.parents[1])
    (tmp_path / 'variables.tf').symlink_to(BASE_PATH / 'variables.tf')
    (tmp_path / 'main.tf').write_text(example.code)
    assets_path = BASE_PATH.parent / str(example.module).replace('-',
                                                                 '_') / 'assets'
    if assets_path.exists():
      (tmp_path / 'assets').symlink_to(assets_path)

    expected_modules = int(match.group(1))
    expected_resources = int(match.group(2))

    if match.group(3) is not None:
      requested_files = match.group(3).split(',')
      for f in requested_files:
        destination = tmp_path / example.files[f].path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(example.files[f].content)

    inventory = []
    if match.group(4) is not None:
      python_test_path = str(example.module).replace('-', '_')
      inventory = BASE_PATH.parent / python_test_path / 'examples'
      inventory = inventory / match.group(4)

    # TODO: force plan_validator to never copy files (we're already
    # running from a temp dir)
    summary = plan_validator(module_path=tmp_path, inventory_paths=inventory,
                             tf_var_files=[])

    print("\n")
    print(yaml.dump({"values": summary.values}))
    print(yaml.dump({"counts": summary.counts}))
    print(yaml.dump({"outputs": summary.outputs}))

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
