#!/usr/bin/env python3

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
'''Format Terraform code blocks with tftest directives in README files.'''

import os
import subprocess
import sys
from pathlib import Path

import click
import marko

# Add fabric root to sys.path to import from tests
FABRIC_ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(FABRIC_ROOT))

try:
  from tests.examples.utils import get_tftest_directive
except ImportError:
  print('Error: Could not import tests.examples.utils', file=sys.stderr)
  sys.exit(1)


def find_readme_files(paths):
  '''Find all README.md files in the given paths.'''
  files_to_check = []
  for path in paths:
    if os.path.isfile(path) and os.path.basename(path) == 'README.md':
      files_to_check.append(path)
    elif os.path.isdir(path):
      for root, _, files in os.walk(path):
        if 'README.md' in files:
          files_to_check.append(os.path.join(root, 'README.md'))
  return files_to_check


def find_examples(content):
  '''Find all Terraform examples with tftest directives in the markdown content.'''
  doc = marko.parse(content)
  examples = []
  last_header = None
  index = 0
  for child in doc.children:
    if isinstance(child, marko.block.Heading):
      last_header = child.children[0].children
      index = 0
      continue
    if not isinstance(child, marko.block.FencedCode):
      continue
    index += 1
    if child.lang not in ('hcl', 'tfvars'):
      continue
    code = child.children[0].children
    directive = get_tftest_directive(code)
    # identical logic to pytest tests filtering
    if directive is None:
      continue
    if 'skip' in directive.args:
      continue
    example_id = f'{last_header}:{index}'
    examples.append((example_id, child.lang, code))
  return examples


def format_example(code):
  '''Format a single Terraform example using terraform fmt.'''
  try:
    proc = subprocess.run(['terraform', 'fmt', '-'], input=code, text=True,
                          capture_output=True, check=True)
    return proc.stdout, None
  except subprocess.CalledProcessError as e:
    return code, e.stderr


def replace_examples(content, formatted_examples):
  '''Replace the original examples with the formatted ones in the markdown content.'''
  new_content = content
  for lang, original_code, formatted_code in formatted_examples:
    if original_code != formatted_code:
      old_block = f'```{lang}\n{original_code}```'
      new_block = f'```{lang}\n{formatted_code}```'
      new_content = new_content.replace(old_block, new_block)
  return new_content


@click.command()
@click.argument('paths', type=click.Path(exists=True), nargs=-1)
@click.option('--check', is_flag=True,
              help='Check if files need formatting without changing them.')
def main(paths, check):
  '''Format Terraform code blocks with tftest directives in README files.

  PATHS can be specific README.md files or directories to search recursively.
  If no paths are provided, searches the current directory recursively.
  '''
  if not paths:
    paths = ('.',)
  files_to_check = find_readme_files(paths)
  has_changes = False
  for file_path in files_to_check:
    try:
      with open(file_path, 'r') as f:
        content = f.read()
      examples = find_examples(content)
      formatted_examples = []
      file_changed = False
      file_output = []
      for example_id, lang, code in examples:
        formatted_code, error = format_example(code)
        if error:
          file_output.append(f'  ❌ {example_id}')
          formatted_examples.append((lang, code, code))
        else:
          if formatted_code != code:
            file_output.append(f'  ✅ {example_id}')
            file_changed = True
            has_changes = True
          formatted_examples.append((lang, code, formatted_code))
      if file_output:
        print(f'{file_path}:')
        for line in file_output:
          print(line)
      if file_changed and not check:
        new_content = replace_examples(content, formatted_examples)
        with open(file_path, 'w') as f:
          f.write(new_content)
    except Exception as e:
      print(f'Error processing {file_path}: {e}', file=sys.stderr)
  if check and has_changes:
    sys.exit(1)


if __name__ == '__main__':
  main()
