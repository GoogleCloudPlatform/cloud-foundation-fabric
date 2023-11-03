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

from pathlib import Path
from ..examples.test_plan import COUNT_TEST_RE, prepare_files

BASE_PATH = Path(__file__).parent


def test_example(e2e_validator, tmp_path, examples_e2e, e2e_tfvars_path):
  (tmp_path / 'fabric').symlink_to(BASE_PATH.parents[1])
  (tmp_path / 'variables.tf').symlink_to(BASE_PATH.parent / 'examples' / 'variables.tf')
  (tmp_path / 'main.tf').write_text(examples_e2e.code)
  assets_path = BASE_PATH.parent / str(examples_e2e.module).replace(
      '-', '_') / 'assets'
  if assets_path.exists():
    (tmp_path / 'assets').symlink_to(assets_path)
  (tmp_path / 'terraform.tfvars').symlink_to(e2e_tfvars_path)

  # add files the same way as it is done for examples
  if match := COUNT_TEST_RE.search(examples_e2e.code):
      prepare_files(examples_e2e, tmp_path, match.group("files"))

  e2e_validator(module_path=tmp_path, extra_files=[],
                tf_var_files=[(tmp_path / 'terraform.tfvars')])
