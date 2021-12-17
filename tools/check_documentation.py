#!/usr/bin/env python3

# Copyright 2021 Google LLC
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

import enum
import pathlib

import click
import tfdoc


BASEDIR = pathlib.Path(__file__).resolve().parents[1]


State = enum.Enum('State', 'OK FAIL SKIP')


def _check_dir(dir_name):
  dir_path = BASEDIR / dir_name
  for readme_path in dir_path.glob('**/README.md'):
    readme = readme_path.read_text()
    mod_name = str(readme_path.relative_to(dir_path).parent)
    result = tfdoc.get_doc(readme)
    if not result:
      state = State.SKIP
    else:
      new_doc = tfdoc.create_doc(readme_path.parent)
      state = State.OK if new_doc == result['doc'] else State.FAIL
    yield mod_name, state


@click.command()
@click.argument('dirs', type=str, nargs=-1)
def main(dirs):
  'Cycle through modules and ensure READMEs are up-to-date.'
  state_labels = {State.FAIL: '✗', State.OK: '✓', State.SKIP: '?'}
  for dir_name in dirs:
    print(f'----- {dir_name} -----')
    for mod_name, state in _check_dir(dir_name):
      print(f'[{state_labels[state]}] {mod_name}')


if __name__ == '__main__':
  main()
