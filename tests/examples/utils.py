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

import collections
import os
import re
from pathlib import Path
import marko

Directive = collections.namedtuple('Directive', 'name args kwargs')
TerraformExample = collections.namedtuple(
    'TerraformExample', 'name code module files fixtures type directive')
YamlExample = collections.namedtuple('YamlExample',
                                     'body module schema directive')
File = collections.namedtuple('File', 'path content')


def get_tftest_directive(s):
  """Scan a code block and return a Directive object if there are any
  tftest directives"""
  regexp = rf"^ *# *(tftest\S*)(.*)$"
  if match := re.search(regexp, s, re.M):
    name, body = match.groups()
    args = []
    kwargs = {}
    for arg in body.split():
      if '=' in arg:
        l, r = arg.split('=', 1)
        kwargs[l] = r
      else:
        args.append(arg)
    return Directive(name, args, kwargs)
  return None


def get_readme_examples(readme_path, fabric_root):
  """Find all code examples tagged for testing in a README file."""
  readme_path = readme_path.resolve()
  fabric_root = fabric_root.resolve()
  doc = marko.parse(readme_path.read_text())
  module = readme_path.parent
  path = module.relative_to(fabric_root)

  files = collections.defaultdict(dict)
  fixtures = {}
  examples = []

  # first pass: collect all examples tagged with tftest-file or tftest-fixture
  last_header = None
  for child in doc.children:
    if isinstance(child, marko.block.FencedCode):
      code = child.children[0].children
      directive = get_tftest_directive(code)
      if directive is None:
        continue
      if directive.name == 'tftest-file':
        name, filepath = directive.kwargs['id'], directive.kwargs['path']
        files[last_header][name] = File(filepath, code)
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

      if child.lang in ('hcl', 'tfvars'):
        name = f'{path}:{last_header}'
        if index > 1:
          name += f' {index}'
        example_id = f'terraform:{path}:{last_header}:{index}'

        marks = []
        if 'serial' in directive.args:
          marks.append('serial')

        example = TerraformExample(name, code, path, files[last_header],
                                   fixtures, child.lang, directive)
        examples.append((example, example_id, marks, last_header, index))
      elif child.lang == "yaml":
        schema = directive.kwargs.get('schema')
        if directive.name == "tftest-file" and schema:
          schema = module / 'schemas' / schema
          example = YamlExample(code, module, schema, directive)
          yaml_path = directive.kwargs['path']
          example_id = f'yaml:{path}:{last_header}:{yaml_path}:{index}'
          examples.append((example, example_id, [], last_header, index))
    elif isinstance(child, marko.block.Heading):
      last_header = child.children[0].children
      index = 0

  return examples
