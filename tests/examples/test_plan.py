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

import re
from pathlib import Path

BASE_PATH = Path(__file__).parent
COUNT_TEST_RE = re.compile(r'# tftest modules=(\d+) resources=(\d+)')
FILE_TEST_RE = re.compile(r'# tftest file (.+)')


def test_example(recursive_e2e_plan_runner, tmp_path, example):
  (tmp_path / 'fabric').symlink_to(Path(BASE_PATH, '../../').resolve())
  (tmp_path / 'variables.tf').symlink_to(
      Path(BASE_PATH, 'variables.tf').resolve())
  (tmp_path / 'configs').symlink_to(Path(BASE_PATH, 'configs').resolve())
  (tmp_path / 'main.tf').write_text(example)

  if match := COUNT_TEST_RE.search(example):
    expected_modules = int(match.group(1)) if match is not None else 1
    expected_resources = int(match.group(2)) if match is not None else 1

    num_modules, num_resources = recursive_e2e_plan_runner(
        str(tmp_path), tmpdir=False)
    assert expected_modules == num_modules, 'wrong number of modules'
    assert expected_resources == num_resources, 'wrong number of resources'

  elif match := FILE_TEST_RE.search(example):
    filename = tmp_path / match.group(1)
    assert filename.exists(), f'cant read {filename}'

    file_content = filename.read_text()

    # skip first line
    file_content = file_content.split('\n', 1)[1]
    example = example.split('\n', 1)[1]
    assert file_content == example, "README inline file and fixture file don't match"

  else:
    assert False, "can't find tftest directive"
