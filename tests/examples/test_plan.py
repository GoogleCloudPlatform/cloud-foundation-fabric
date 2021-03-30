# Copyright 2021 Google LLC
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

import tftest
import re
import tempfile
from pathlib import Path

import marko

MODULES_PATH = Path(__file__, '../../../modules/').resolve()
VARIABLES_PATH = Path(__file__, '../variables.tf').resolve()
EXPECTED_RESOURCES_RE = re.compile(r'# tftest:modules=(\d+):resources=(\d+)')


def test_example(example_plan_runner, tmp_path, example):
  (tmp_path / 'modules').symlink_to(MODULES_PATH)
  (tmp_path / 'variables.tf').symlink_to(VARIABLES_PATH)
  (tmp_path / 'main.tf').write_text(example)

  match = EXPECTED_RESOURCES_RE.search(example)
  expected_modules = int(match.group(1)) if match is not None else 1
  expected_resources = int(match.group(2)) if match is not None else 1

  num_modules, num_resources = example_plan_runner(str(tmp_path))
  assert expected_modules == num_modules
  assert expected_resources == num_resources
