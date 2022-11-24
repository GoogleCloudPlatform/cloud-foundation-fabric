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
COUNT_TEST_RE = re.compile(
    r'# tftest modules=(\d+) resources=(\d+)(?: files=([\w,]+))?')


def test_example(recursive_e2e_plan_runner, tmp_path, example):
  if match := COUNT_TEST_RE.search(example.code):
    (tmp_path / 'fabric').symlink_to(Path(BASE_PATH, '../../'))
    (tmp_path / 'variables.tf').symlink_to(Path(BASE_PATH, 'variables.tf'))
    (tmp_path / 'main.tf').write_text(example.code)

    if match.group(3) is not None:
      requested_files = match.group(3).split(',')
      for f in requested_files:
        destination = tmp_path / example.files[f].path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(example.files[f].content)

    expected_modules = int(match.group(1)) if match is not None else 1
    expected_resources = int(match.group(2)) if match is not None else 1

    num_modules, num_resources = recursive_e2e_plan_runner(
        str(tmp_path), tmpdir=False)
    assert expected_modules == num_modules, 'wrong number of modules'
    assert expected_resources == num_resources, 'wrong number of resources'

  else:
    assert False, "can't find tftest directive"
