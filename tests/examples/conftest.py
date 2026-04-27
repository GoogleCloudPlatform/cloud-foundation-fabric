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
"""Pytest configuration for testing code examples."""

import collections
import os

from pathlib import Path

import marko
import pytest

from .utils import File, TerraformExample, YamlExample, get_tftest_directive, get_readme_examples

FABRIC_ROOT = Path(__file__).parents[2]


def pytest_generate_tests(metafunc, test_group='example',
                          filter_tests=lambda x: 'skip' not in x):
  """Find all README.md files and collect code examples tagged for testing."""
  if test_group in metafunc.fixturenames:
    readmes = FABRIC_ROOT.glob('**/README.md')
    examples = []
    ids = []

    for readme in readmes:
      readme_examples = get_readme_examples(readme, FABRIC_ROOT)
      for example, example_id, marks, header, index in readme_examples:
        if isinstance(example, TerraformExample):
          if not filter_tests(example.directive.args):
            continue
          if os.environ.get(
              'TERRAFORM') == 'tofu' and 'skip-tofu' in example.directive.args:
            continue

          pytest_marks = [
              pytest.mark.xdist_group('serial') for m in marks if m == 'serial'
          ]
          examples.append(pytest.param(example, marks=pytest_marks))
          ids.append(example_id)
        elif isinstance(example, YamlExample):
          examples.append(pytest.param(example))
          ids.append(example_id)

    metafunc.parametrize(test_group, examples, ids=ids)
