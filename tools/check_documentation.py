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
import sys

import click
import tfdoc

BASEDIR = pathlib.Path(__file__).resolve().parents[1]


class DocState(enum.Enum):
  OK = 1
  FAIL = 2
  UNKNOWN = 3

  def __str__(self):
    return {
        self.FAIL.value: '✗',
        self.OK.value: '✓',
        self.UNKNOWN.value: '?'
    }[self.value]


def check_path(pathname):
  path = BASEDIR / pathname
  subpaths = sorted(list(path.iterdir()))
  for subpath in subpaths:
    errors = []
    if not subpath.is_dir():
      continue
    if subpath.stem.startswith('_'):
      continue

    doc = subpath / 'README.md'
    if not doc.exists():
      errors.append(f'{doc} does not exist')

    variables = tfdoc.get_variables(subpath)
    variable_names = [v.name for v in variables]
    for variable in variables:
      if not variable.description:
        errors.append(f'variable {variable.name} has no description')
    if sorted(variable_names) != variable_names:
      message = f'variable order should be: {sorted(variable_names)}'
      errors.append(message)

    outputs = tfdoc.get_outputs(subpath)
    output_names = [v.name for v in outputs]
    for output in outputs:
      if not output.description:
        errors.append(f'output {output.name} has no description')
    if sorted(output_names) != output_names:
      message = f'output order should be: {sorted(output_names)}'
      errors.append(message)

    state = tfdoc.check_state(subpath)
    if state is False:
      errors.append("documentation is out of date")
    elif state:
      pass
    else:
      yield DocState.UNKNOWN, subpath.stem, errors
      continue

    yield DocState.FAIL if errors else DocState.OK, subpath.stem, errors


@click.command()
@click.argument('paths', type=str, nargs=-1)
def main(paths):
  "Cycle through modules and ensure READMEs are up-to-date."
  error = False
  for path in paths:
    print(f'checking {path}')
    for state, name, errors in check_path(path):
      if state == DocState.FAIL:
        error = True
      print(f'  [{state}] {name}')
      for error in errors:
        print(f'      {error}')
  if error:
    print('errors were present')
    sys.exit(1)


if __name__ == '__main__':
  main()
