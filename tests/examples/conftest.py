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

from pathlib import Path

import marko


MODULES_PATH = Path(__file__).parents[2] / 'modules/'


def pytest_generate_tests(metafunc):
  if 'example' in metafunc.fixturenames:
    modules = [
      x for x in MODULES_PATH.iterdir()
      if x.is_dir()
    ]
    modules.sort()
    examples = []
    ids = []
    for module in modules:
      readme = module / 'README.md'
      if not readme.exists(): continue
      doc = marko.parse(readme.read_text())
      index = 0
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode) and child.lang == 'hcl':
          index += 1
          code = child.children[0].children
          if 'tftest:skip' in code:
            continue
          examples.append(code)
          ids.append(f'{module.stem}:example{index}')

    metafunc.parametrize('example', examples, ids=ids)
