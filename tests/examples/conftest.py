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

import collections
import re
from pathlib import Path

import marko
import pytest

FABRIC_ROOT = Path(__file__).parents[2]
BLUEPRINTS_PATH = FABRIC_ROOT / 'blueprints/'
MODULES_PATH = FABRIC_ROOT / 'modules/'
SUBMODULES_PATH = MODULES_PATH / 'cloud-config-container'

FILE_TEST_RE = re.compile(r'# tftest-file id=(\w+) path=([\S]+)')

Example = collections.namedtuple('Example', 'code module files')
File = collections.namedtuple('File', 'path content')


def pytest_generate_tests(metafunc):
  if 'example' in metafunc.fixturenames:
    modules = [x for x in MODULES_PATH.iterdir() if x.is_dir()]
    modules.extend(x for x in SUBMODULES_PATH.iterdir() if x.is_dir())
    modules.extend(x for x in BLUEPRINTS_PATH.glob("*/*") if x.is_dir())
    modules.sort()
    examples = []
    ids = []

    for module in modules:
      readme = module / 'README.md'
      if not readme.exists():
        continue
      doc = marko.parse(readme.read_text())
      index = 0
      files = collections.defaultdict(dict)

      # first pass: collect all examples tagged with tftest-file
      last_header = None
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode):
          code = child.children[0].children
          match = FILE_TEST_RE.search(code)
          if match:
            name, path = match.groups()
            files[last_header][name] = File(path, code)
        elif isinstance(child, marko.block.Heading):
          last_header = child.children[0].children

      # second pass: collect all examples tagged with tftest
      last_header = None
      index = 0
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode):
          index += 1
          code = child.children[0].children
          if 'tftest skip' in code:
            continue
          if child.lang == 'hcl':
            path = module.relative_to(FABRIC_ROOT)
            examples.append(Example(code, path, files[last_header]))
            name = f'{path}:{last_header}'
            if index > 1:
              name += f' {index}'
            ids.append(name)
        elif isinstance(child, marko.block.Heading):
          last_header = child.children[0].children
          index = 0

    metafunc.parametrize('example', examples, ids=ids)
