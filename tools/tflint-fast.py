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
import glob
import subprocess
import yaml

from pathlib import Path
import os
import shutil
import tempfile

BASEDIR = Path(__file__).parents[1]

# if we're copying the module, we might as well ignore files and
# directories that are automatically read by terraform. Useful
# to avoid surprises if, for example, you have an active fast
# deployment with links to configs)
ignore_patterns = shutil.ignore_patterns('*.auto.tfvars', '*.auto.tfvars.json',
                                         '[0-9]-*-providers.tf',
                                         'terraform.tfstate*',
                                         '.terraform.lock.hcl',
                                         'terraform.tfvars', '.terraform')


def tflint_module(module_path, var_path, extra_dirs, junit):
  with tempfile.TemporaryDirectory(dir=module_path.parent) as tmp_path:
    tmp_path = Path(tmp_path)

    # Running tests in a copy made with symlinks=True makes them run
    # ~20% slower than when run in a copy made with symlinks=False.
    shutil.copytree(BASEDIR / module_path, tmp_path, dirs_exist_ok=True,
                    symlinks=False, ignore=ignore_patterns)

    for extra_dir in extra_dirs:
      os.symlink(extra_dir, tmp_path / extra_dir.name)
    args = ['tflint']
    if junit:
      args += ['--format=junit']
    args += [
        '--chdir',
        str(tmp_path.absolute()),
        '--var-file',
        str((BASEDIR / var_path).absolute()),
        '--config',
        str((BASEDIR / ".tflint.hcl").absolute()),
    ]
    if junit:
      with open(f'tflint-fast-{str(module_path).replace("/", "_")}.xml',
                'w+') as output:
        return subprocess.run(args, stderr=subprocess.STDOUT,
                              stdout=output).returncode
    else:
      return subprocess.run(args, stderr=subprocess.STDOUT).returncode


def is_affected(files, module_path, tftest_path, extra_dirs):
  # no files provided, run all tftests
  if not files:
    return True
  absolute_files = [Path(x).absolute() for x in files]
  # check if the files modified the module
  ret = any(x.is_relative_to(module_path.absolute()) for x in absolute_files)
  if ret:
    return ret
  # check if the files modified the test definition
  ret = any(x.is_relative_to(tftest_path.absolute()) for x in absolute_files)
  if ret:
    return ret
  # check if the files modified extra dirs
  for extra_dir in extra_dirs:
    ret = any(x.is_relative_to(extra_dir.absolute()) for x in absolute_files)
    if ret:
      return ret
  return False


@click.option('--junit', default=False, is_flag=True)
@click.argument('files', nargs=-1, type=click.Path(), required=False)
@click.command()
def main(junit, files):
  ret = 0
  for tftest_yaml in sorted(
      glob.glob(f'{BASEDIR}/tests/fast/**/tftest.yaml', recursive=True)):
    with open(tftest_yaml, 'r') as f:
      tftest = yaml.safe_load(f)
    module_path = Path(tftest['module'])
    tftest_path = Path(tftest_yaml).parent
    simple_test = tftest['tests'].get('simple', {})
    if not simple_test:
      simple_test = {}
    relative_extra_dirs = simple_test.get('extra_dirs')
    extra_dirs = [
        (module_path.absolute() / Path(x)) for x in relative_extra_dirs
    ] if relative_extra_dirs else []
    var_path = (tftest_path / 'simple.tfvars')

    if not var_path.exists():
      print(f'## {module_path}: skipping stage as no simple.tfvars found there')
      continue
    if not is_affected(files, module_path, tftest_path, extra_dirs):
      print(
          f'## {module_path}: skipping stage as it is not affected by provided files'
      )
      continue
    click.echo(f'## {module_path}')
    ret |= tflint_module(module_path, var_path, extra_dirs, junit)
    # end for
  exit(ret)


if __name__ == '__main__':
  main()
