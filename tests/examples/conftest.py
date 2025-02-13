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
from pathlib import Path

import marko
import pytest

from .utils import File, TerraformExample, YamlExample, get_tftest_directive

FABRIC_ROOT = Path(__file__).parents[2]


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
          directive = get_tftest_directive(code)
          if directive is None:
            continue
          if directive.name == 'tftest-file':
            name, path = directive.kwargs['id'], directive.kwargs['path']
            files[last_header][name] = File(path, code)
          if directive.name == 'tftest-fixture':
            name = directive.kwargs['id']
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
          directive = get_tftest_directive(code)
          if directive is None:
            continue
          if directive and not filter_tests(directive.args):
            continue
          if child.lang in ('hcl', 'tfvars'):
            path = module.relative_to(FABRIC_ROOT)
            name = f'{path}:{last_header}'
            if index > 1:
              name += f' {index}'
            ids.append(f'terraform:{path}:{last_header}:{index}')
            # if test is marked with 'serial' in tftest line then add them to this xdist group
            # this, together with `--dist loadgroup` will ensure that those tests will be run one after another
            # even if multiple workers are used
            # see: https://pytest-xdist.readthedocs.io/en/latest/distribution.html
            marks = [pytest.mark.xdist_group('serial')
                    ] if 'serial' in directive.args else []
            example = TerraformExample(name, code, path, files[last_header],
                                       fixtures, child.lang, directive)
            examples.append(pytest.param(example, marks=marks))
          elif child.lang == "yaml":
            schema = directive.kwargs.get('schema')
            name = directive.kwargs.get('id')
            if directive.name == "tftest-file" and schema:
              schema = module / 'schemas' / schema
              example = YamlExample(code, module, schema)
              yaml_path = directive.kwargs['path']
              ids.append(f'yaml:{path}:{last_header}:{yaml_path}:{index}')
              examples.append(pytest.param(example))
        elif isinstance(child, marko.block.Heading):
          last_header = child.children[0].children
          index = 0

    metafunc.parametrize(test_group, examples, ids=ids)
