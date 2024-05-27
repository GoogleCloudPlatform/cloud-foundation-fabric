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
import re
from pathlib import Path

import marko
import pytest

FABRIC_ROOT = Path(__file__).parents[2]

FILE_TEST_RE = re.compile(r'# tftest-file +id=([\w_.-]+) +path=([\S]+)')
FIXTURE_TEST_RE = re.compile(r'# tftest-fixture +id=([\w_.-]+)')

Example = collections.namedtuple('Example',
                                 'name code module files fixtures type')
File = collections.namedtuple('File', 'path content')


def get_tftest_directive(s):
  """Returns tftest directive from code block or None when directive is not found"""
  for x in s.splitlines():
    if x.strip().startswith("#") and 'tftest' in x:
      return x
  return None


def pytest_generate_tests(metafunc, test_group='example',
                          filter_tests=lambda x: 'skip' not in x):
  """Find all README.md files and collect code examples tagged for testing."""
  if test_group in metafunc.fixturenames:
    readmes = FABRIC_ROOT.glob('**/README.md')
    examples = []
    ids = []

    for readme in readmes:
      module = readme.parent
      doc = marko.parse(readme.read_text())
      index = 0
      files = collections.defaultdict(dict)
      fixtures = {}

      # first pass: collect all examples tagged with tftest-file
      last_header = None
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode):
          code = child.children[0].children
          if match := FILE_TEST_RE.search(code):
            name, path = match.groups()
            files[last_header][name] = File(path, code)
          if match := FIXTURE_TEST_RE.search(code):
            name = match.groups()[0]
            fixtures[name] = code
        elif isinstance(child, marko.block.Heading):
          last_header = child.children[0].children

      # second pass: collect all examples tagged with tftest
      last_header = None
      index = 0
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode):
          index += 1
          code = child.children[0].children
          tftest_tag = get_tftest_directive(code)
          if tftest_tag is None:
            continue
          if tftest_tag and not filter_tests(tftest_tag):
            continue
          if child.lang in ('hcl', 'tfvars'):
            path = module.relative_to(FABRIC_ROOT)
            name = f'{path}:{last_header}'
            if index > 1:
              name += f' {index}'
            ids.append(f'{path}:{last_header}:{index}')
            # if test is marked with 'serial' in tftest line then add them to this xdist group
            # this, together with `--dist loadgroup` will ensure that those tests will be run one after another
            # even if multiple workers are used
            # see: https://pytest-xdist.readthedocs.io/en/latest/distribution.html
            marks = [pytest.mark.xdist_group("serial")
                    ] if 'serial' in tftest_tag else []
            example = Example(name, code, path, files[last_header], fixtures,
                              child.lang)
            examples.append(pytest.param(example, marks=marks))
        elif isinstance(child, marko.block.Heading):
          last_header = child.children[0].children
          index = 0

    metafunc.parametrize(test_group, examples, ids=ids)
