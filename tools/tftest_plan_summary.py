#!/usr/bin/env python3

# Copyright 2025 Google LLC
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
import yaml

from pathlib import Path

try:
  import fixtures
except ImportError:
  BASEDIR = Path(__file__).parents[1]
  sys.path.append(str(BASEDIR / 'tests'))
  import fixtures


@click.command()
@click.argument('test_file', type=click.Path(), nargs=1)
@click.argument('test_name', nargs=1)
def main(test_file, test_name):
  test_base_dir = Path(test_file).parent
  try:
    with open(test_file) as f:
      raw = yaml.safe_load(f)
    module = raw.pop('module')
  except (IOError, OSError, yaml.YAMLError) as e:
    raise Exception(f'cannot read test spec {test_file}: {e}')
  except KeyError as e:
    raise Exception(f'`module` key not found in {test_file}: {e}')

  common = raw.pop('common_tfvars', [])
  spec = raw.get('tests', {})[test_name] or {}
  extra_dirs = spec.get('extra_dirs', [])
  extra_files = spec.get('extra_files', [])
  tf_var_files = common + [f'{test_name}.tfvars'] + spec.get('tfvars', [])
  module_path = BASEDIR / module
  summary = fixtures.plan_summary(module_path, test_base_dir, tf_var_files,
                                  extra_files=extra_files,
                                  extra_dirs=extra_dirs)

  print(yaml.dump({'values': summary.values}))
  print(yaml.dump({'counts': summary.counts}))
  outputs = {
      k: v.get('value', '__missing__') for k, v in summary.outputs.items()
  }
  print(yaml.dump({'outputs': outputs}))


if __name__ == '__main__':
  main()
