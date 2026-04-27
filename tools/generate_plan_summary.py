#!/usr/bin/env python3

# Copyright 2026 Google LLC
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

# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "click",
#    "marko",
#    "pytest>=7.2.1",
#    "PyYAML>=6.0",
#    "tftest>=1.8.1",
# ]
# ///
"""Generate plan summary for README examples or tftest.yaml tests.

This script unifies the functionality of generating inventory files from
either README code blocks or tftest.yaml test specifications.
"""

import collections
import datetime
import glob
import os
import re
import shutil
import sys
import tempfile
import click
import marko
import yaml

from pathlib import Path

BASEDIR = Path(__file__).parents[1]
sys.path.append(str(BASEDIR / 'tests'))

try:
  import fixtures
  from examples.utils import get_readme_examples, get_tftest_directive
except ImportError as e:
  print(f"Error importing fixtures or utils: {e}")
  sys.exit(1)

FILTERED_ATTRIBUTES = [
    'source_md5hash',
]

HEADER = "".join(open(__file__).readlines()[2:15])
current_year = datetime.date.today().year
HEADER = re.sub(r"Copyright \d{4}", f"Copyright {current_year}", HEADER)


def output_summary(summary, inventory_path, save):
  values = fixtures.filter_plan_values(summary.values, FILTERED_ATTRIBUTES)
  outputs = {
      k: v.get('value', '__missing__') for k, v in summary.outputs.items()
  }

  if save:
    if not inventory_path:
      print("Error: Cannot determine inventory path for saving.")
      sys.exit(1)
    inventory_path.parent.mkdir(parents=True, exist_ok=True)
    with open(inventory_path, 'w') as f:
      f.write(HEADER)
      f.write('\n')
      yaml.dump({'values': values}, f)
      f.write('\n')
      yaml.dump({'counts': summary.counts}, f)
      f.write('\n')
      yaml.dump({'outputs': outputs}, f)
    print(f"Inventory saved to {inventory_path}")
  else:
    print(yaml.dump({'values': values}))
    print(yaml.dump({'counts': summary.counts}))
    print(yaml.dump({'outputs': outputs}))


def prepare_files(test_path, files, fixtures_dict, requested_files,
                  requested_fixtures):
  if requested_files:
    for f in requested_files.split(','):
      if f in files:
        destination = test_path / files[f].path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(files[f].content)

  if requested_fixtures:
    for f in requested_fixtures.split(','):
      if f.startswith('fixtures/'):
        source = BASEDIR / 'tests' / f
        destination = test_path / source.name
        if not destination.exists():
          destination.symlink_to(source)
      elif f in fixtures_dict:
        destination = test_path / f'{f}.tf'
        destination.write_text(fixtures_dict[f])


def handle_readme(readme_path, target, index, save):
  examples = get_readme_examples(readme_path, BASEDIR)
  header = target

  if not header:
    headers = sorted(
        set(exp_header
            for exp, example_id, marks, exp_header, exp_index in examples
            if exp_header))
    if not headers:
      print(f"No tests found in {readme_path}")
      sys.exit(0)

    print("Available headers with tests:")
    for i, h in enumerate(headers, 1):
      print(f" {i}. {h}")

    choice = click.prompt("Select a header by number", type=int)
    if 1 <= choice <= len(headers):
      header = headers[choice - 1]
    else:
      print("Invalid selection")
      sys.exit(1)

  target_example = None
  for exp, example_id, marks, exp_header, exp_index in examples:
    if exp_header == header and exp_index == index:
      target_example = exp
      break

  if not target_example:
    print(f"Test not found for header '{header}' and index {index}")
    sys.exit(1)

  directive = target_example.directive
  module_path = readme_path.parent

  inventory_path = None
  if save:
    inventory_name = directive.kwargs.get('inventory')
    if not inventory_name:
      print("Error: No inventory file specified in the # tftest directive.")
      print("Please add `inventory=filename.yaml` to the directive first.")
      sys.exit(1)
    module_str = str(target_example.module).replace('-', '_')
    inventory_path = (BASEDIR / 'tests' / module_str / 'examples' /
                      inventory_name)

  with tempfile.TemporaryDirectory(prefix='tftest-') as tmp_path:
    tmp_path = Path(tmp_path)

    if target_example.type == 'hcl':
      (tmp_path / 'fabric').symlink_to(BASEDIR)
      (tmp_path / 'variables.tf').symlink_to(BASEDIR / 'tests' / 'examples' /
                                             'variables.tf')
      (tmp_path / 'main.tf').write_text(target_example.code)

      assets_path = module_path / 'assets'
      if assets_path.exists():
        (tmp_path / 'assets').symlink_to(assets_path)

      prepare_files(tmp_path, target_example.files, target_example.fixtures,
                    directive.kwargs.get('files'),
                    directive.kwargs.get('fixtures'))

      summary = fixtures.plan_summary(tmp_path, Path(), [])
    elif target_example.type == 'tfvars':
      (tmp_path / 'terraform.auto.tfvars').write_text(target_example.code)
      shutil.copytree(module_path, tmp_path, dirs_exist_ok=True)
      summary = fixtures.plan_summary(tmp_path, Path(),
                                      [tmp_path / 'terraform.auto.tfvars'])

    output_summary(summary, inventory_path, save)


def handle_tftest(test_file, target, save):
  test_base_dir = Path(test_file).parent
  with open(test_file) as f:
    raw = yaml.safe_load(f)
  module = raw.pop('module')
  test_name = target

  if not test_name:
    tests = sorted(raw.get('tests', {}).keys())
    if not tests:
      print(f"No tests found in {test_file}")
      sys.exit(0)

    print("Available tests:")
    for i, t in enumerate(tests, 1):
      print(f" {i}. {t}")

    choice = click.prompt("Select a test by number", type=int)
    if 1 <= choice <= len(tests):
      test_name = tests[choice - 1]
    else:
      print("Invalid selection")
      sys.exit(1)

  common = raw.pop('common_tfvars', [])
  spec = raw.get('tests', {})[test_name] or {}
  extra_dirs = spec.get('extra_dirs', [])
  extra_files = spec.get('extra_files', [])
  tf_var_files = common + [f'{test_name}.tfvars'] + spec.get('tfvars', [])
  module_path = BASEDIR / module
  summary = fixtures.plan_summary(module_path, test_base_dir, tf_var_files,
                                  extra_files=extra_files,
                                  extra_dirs=extra_dirs)

  inventory_path = test_base_dir / f'{test_name}.yaml' if save else None
  output_summary(summary, inventory_path, save)


@click.command()
@click.argument('file_path', type=click.Path(exists=True), nargs=1)
@click.argument('target', required=False)
@click.option('--index', default=1,
              help='Index of the test under the header (README only)')
@click.option('--save', is_flag=True,
              help='Automatically save inventory to the right location')
def main(file_path, target, index, save):
  """Generate plan summary for a README example or a tftest.yaml test.

  FILE_PATH: Path to README.md or tftest.yaml.
  TARGET: Header name (for README) or test name (for tftest.yaml).
  """
  file_path = Path(file_path)

  if file_path.suffix == '.md' or file_path.name == 'README.md':
    handle_readme(file_path, target, index, save)
  elif file_path.suffix in ('.yaml', '.yml') or file_path.name == 'tftest.yaml':
    handle_tftest(file_path, target, save)
  else:
    print(f"Unsupported file type: {file_path.suffix}")
    print("Please provide a README.md or a tftest.yaml file.")
    sys.exit(1)


if __name__ == '__main__':
  main()
