#!/usr/bin/env python3

# Copyright 2022 Google LLC
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
'''Recursively check freshness of tfdoc's generated tables in README files.

This tool recursively checks that the embedded variables and outputs tables in
README files, match what is generated at runtime by tfdoc based on current
sources. As such, it accepts pretty much the same options as tfdoc does. Its
main use is in CI pipelines triggered by pull requests.
'''

import difflib
import enum
import pathlib

import click
import tfdoc

BASEDIR = pathlib.Path(__file__).resolve().parents[1]


class State(enum.IntEnum):
  SKIP = enum.auto()
  OK = enum.auto()
  FAIL_STALE_README = enum.auto()
  FAIL_UNSORTED_VARS = enum.auto()
  FAIL_UNSORTED_OUTPUTS = enum.auto()
  FAIL_VARIABLE_PERIOD = enum.auto()
  FAIL_OUTPUT_PERIOD = enum.auto()
  FAIL_VARIABLE_DESCRIPTION = enum.auto()
  FAIL_OUTPUT_DESCRIPTION = enum.auto()

  @property
  def failed(self):
    return self.value > State.OK

  @property
  def label(self):
    return {
        State.SKIP: '  ',
        State.OK: '✓ ',
        State.FAIL_STALE_README: '✗R',
        State.FAIL_UNSORTED_VARS: 'SV',
        State.FAIL_UNSORTED_OUTPUTS: 'SO',
        State.FAIL_VARIABLE_PERIOD: '.V',
        State.FAIL_OUTPUT_PERIOD: '.O',
        State.FAIL_VARIABLE_DESCRIPTION: 'DV',
        State.FAIL_OUTPUT_DESCRIPTION: 'DO',
    }[self.value]


def _check_dir(dir_name, exclude_files=None, files=False, show_extra=False):
  'Invoke tfdoc on folder, using the relevant options.'
  dir_path = BASEDIR / dir_name
  for readme_path in sorted(dir_path.glob('**/README.md')):
    if '.terraform' in str(readme_path):
      continue

    diff = None
    readme = readme_path.read_text()
    mod_name = str(readme_path.relative_to(dir_path).parent)
    result = tfdoc.get_doc(readme)
    if not result:
      state = State.SKIP
    else:
      try:
        new_doc = tfdoc.create_doc(readme_path.parent, files, show_extra,
                                   exclude_files, readme)
        # TODO: support variables in multiple files
        newvars = new_doc.variables
        newouts = new_doc.outputs
        variables = [v.name for v in newvars if v.file == "variables.tf"]
        outputs = [o.name for o in newouts if o.file == "outputs.tf"]
      except SystemExit:
        state = state.SKIP
      else:
        state = State.OK

        if new_doc.content != result['doc']:
          state = State.FAIL_STALE_README
          header = f'----- {mod_name} diff -----\n'
          ndiff = difflib.ndiff(result['doc'].split('\n'),
                                new_doc.content.split('\n'))
          diff = '\n'.join([header] + list(ndiff))

        elif empty := [v.name for v in newvars if not v.description]:
          state = state.FAIL_VARIABLE_DESCRIPTION
          diff = "\n".join([
              f'----- {mod_name} variables missing description -----',
              ', '.join(empty),
          ])

        elif empty := [o.name for o in newouts if not o.description]:
          state = state.FAIL_VARIABLE_DESCRIPTION
          diff = "\n".join([
              f'----- {mod_name} outputs missing description -----',
              ', '.join(empty),
          ])

        elif variables != sorted(variables):
          state = state.FAIL_UNSORTED_VARS
          diff = "\n".join([
              f'----- {mod_name} variables -----',
              f'variables should be in this order: ',
              ', '.join(sorted(variables)),
          ])

        elif outputs != sorted(outputs):
          state = state.FAIL_UNSORTED_OUTPUTS
          diff = "\n".join([
              f'----- {mod_name} outputs -----',
              f'outputs should be in this order: ',
              ', '.join(sorted(outputs)),
          ])

        elif nc := [v.name for v in newvars if not v.description.endswith('.')]:
          state = state.FAIL_VARIABLE_PERIOD
          diff = "\n".join([
              f'----- {mod_name} variables missing colons -----',
              ', '.join(nc),
          ])

        elif nc := [o.name for o in newouts if not o.description.endswith('.')]:
          state = state.FAIL_VARIABLE_PERIOD
          diff = "\n".join([
              f'----- {mod_name} outputs missing colons -----',
              ', '.join(nc),
          ])

    yield mod_name, state, diff


@click.command()
@click.argument('dirs', type=str, nargs=-1)
@click.option('--exclude-file', '-x', multiple=True)
@click.option('--files/--no-files', default=False)
@click.option('--show-diffs/--no-show-diffs', default=False)
@click.option('--show-extra/--no-show-extra', default=False)
def main(dirs, exclude_file=None, files=False, show_diffs=False,
         show_extra=False):
  'Cycle through modules and ensure READMEs are up-to-date.'
  print(f'files: {files}, extra: {show_extra}, diffs: {show_diffs}\n')
  errors = []
  for dir_name in dirs:
    print(f'----- {dir_name} -----')
    result = _check_dir(dir_name, exclude_file, files, show_extra)
    for mod_name, state, diff in result:
      if state.failed:
        errors.append((mod_name, diff))
      print(f'[{state.label}] {mod_name}')

  if errors:
    if show_diffs:
      print('Errored diffs:')
      print('\n'.join([e[1] for e in errors]))
    else:
      print('Errored modules:')
      print('\n'.join([e[0] for e in errors]))
    raise SystemExit('Errors found.')


if __name__ == '__main__':
  main()
