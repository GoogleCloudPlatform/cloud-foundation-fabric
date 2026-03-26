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
import re
import subprocess
import sys

import click


def format_hcl_block(match):
  content = match.group(1)
  if '# tftest' not in content:
    return match.group(0)

  try:
    proc = subprocess.run(['terraform', 'fmt', '-'], input=content, text=True,
                          capture_output=True, check=True)
    # The output from terraform fmt usually includes a trailing newline.
    # To keep the format stable, we reconstruct the block exactly.
    return f"```hcl\n{proc.stdout}```"
  except subprocess.CalledProcessError:
    return match.group(0)


@click.command()
@click.argument('paths', type=click.Path(exists=True), nargs=-1)
@click.option('--check', is_flag=True,
              help='Check if files need formatting without changing them.')
def main(paths, check):
  """Format Terraform code blocks with tftest directives in README files.

  PATHS can be specific README.md files or directories to search recursively.
  If no paths are provided, searches the current directory recursively.
  """
  if not paths:
    paths = ('.',)

  files_to_check = []
  for path in paths:
    if os.path.isfile(path) and os.path.basename(path) == 'README.md':
      files_to_check.append(path)
    elif os.path.isdir(path):
      for root, _, files in os.walk(path):
        if 'README.md' in files:
          files_to_check.append(os.path.join(root, 'README.md'))

  changed_files = []

  for file_path in files_to_check:
    try:
      with open(file_path, 'r') as f:
        content = f.read()

      new_content = re.sub(r'(?sm)^```hcl\n(.*?\n)```$', format_hcl_block,
                           content)

      if new_content != content:
        if check:
          print(f"Would format {file_path}")
        else:
          with open(file_path, 'w') as f:
            f.write(new_content)
          print(f"Formatted {file_path}")
        changed_files.append(file_path)

    except Exception as e:
      print(f"Error processing {file_path}: {e}", file=sys.stderr)

  if check and changed_files:
    sys.exit(1)


if __name__ == '__main__':
  main()
