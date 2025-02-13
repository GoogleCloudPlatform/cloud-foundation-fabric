#!/usr/bin/env python3

# Copyright 2023 Google LLC
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

import click
import sys
import tempfile
import yaml

from pathlib import Path

try:
  import fixtures
except ImportError:
  BASEDIR = Path(__file__).parents[1]
  sys.path.append(str(BASEDIR / 'tests'))
  import fixtures


@click.command()
@click.option('--example', default=False, is_flag=True)
@click.option('--extra-files', default=[], multiple=True)
@click.argument('module', type=click.Path(), nargs=1)
@click.argument('tfvars', type=click.Path(exists=True), nargs=-1)
def main(example, module, tfvars, extra_files):
  try:
    if example:
      tmp_dir = tempfile.TemporaryDirectory()
      tmp_path = Path(tmp_dir.name)
      common_vars = BASEDIR / 'tests' / 'examples' / 'variables.tf'
      (tmp_path / 'main.tf').symlink_to(module)
      (tmp_path / 'variables.tf').symlink_to(common_vars)
      (tmp_path / 'fabric').symlink_to(BASEDIR)
      module = tmp_path
    else:
      module = BASEDIR / module

    summary = fixtures.plan_summary(module, Path(), tfvars, extra_files)
    print(yaml.dump({'values': summary.values}))
    print(yaml.dump({'counts': summary.counts}))
    outputs = {
        k: v.get('value', '__missing__') for k, v in summary.outputs.items()
    }
    print(yaml.dump({'outputs': outputs}))
  finally:
    if example:
      tmp_dir.cleanup()


if __name__ == '__main__':
  main()
