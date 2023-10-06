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
  FAIL_STALE_TOC = enum.auto()
  FAIL_UNSORTED_VARS = enum.auto()
  FAIL_UNSORTED_OUTPUTS = enum.auto()
  FAIL_VARIABLE_PERIOD = enum.auto()
  FAIL_OUTPUT_PERIOD = enum.auto()
  FAIL_VARIABLE_DESCRIPTION = enum.auto()
  FAIL_OUTPUT_DESCRIPTION = enum.auto()
  FAIL_MISSING_TYPES = enum.auto()

  @property
  def failed(self):
    return self.value > State.OK

  @property
  def label(self):
    return {
        State.SKIP: '  ',
        State.OK: '✓ ',
        State.FAIL_STALE_README: '✗R',
        State.FAIL_STALE_TOC: '✗T',
        State.FAIL_UNSORTED_VARS: 'SV',
        State.FAIL_UNSORTED_OUTPUTS: 'SO',
        State.FAIL_VARIABLE_PERIOD: '.V',
        State.FAIL_OUTPUT_PERIOD: '.O',
        State.FAIL_VARIABLE_DESCRIPTION: 'DV',
        State.FAIL_OUTPUT_DESCRIPTION: 'DO',
        State.FAIL_MISSING_TYPES: 'TY',
    }[self.value]


def _check_dir(dir_name, exclude_files=None, files=False, show_extra=False):
  'Invoke tfdoc on folder, using the relevant options.'
  dir_path = BASEDIR / dir_name
  for readme_path in sorted(dir_path.glob('**/README.md')):
    if '.terraform' in str(readme_path):
      continue

    diff = None
    readme = readme_path.read_text()
    readme_rel = str(readme_path.relative_to(BASEDIR))
    current_doc = tfdoc.get_tfref_parts(readme)
    current_toc = tfdoc.get_toc_parts(readme)
    if current_doc or current_toc:
      new_doc = tfdoc.create_tfref(readme_path.parent, files, show_extra,
                                   exclude_files, readme)
      new_toc = tfdoc.create_toc(readme)
      newvars = new_doc.variables
      newouts = new_doc.outputs
      variables = [v.name for v in newvars if v.file.endswith('variables.tf')]
      outputs = [o.name for o in newouts if o.file.endswith('outputs.tf')]

      state = State.OK

      if current_doc and new_doc.content != current_doc['doc']:
        state = State.FAIL_STALE_README
        header = f'----- {readme_rel} diff -----\n'
        ndiff = difflib.ndiff(current_doc['doc'].splitlines(keepends=True),
                              new_doc.content.splitlines(keepends=True))
        diff = ''.join([header] + [x for x in ndiff if x[0] != ' '])

      elif current_toc and new_toc != current_toc['toc']:
        state = State.FAIL_STALE_TOC
        header = f'----- {readme_rel} diff -----\n'
        ndiff = difflib.ndiff(current_toc['toc'].splitlines(keepends=True),
                              new_toc.splitlines(keepends=True))
        diff = ''.join([header] + [x for x in ndiff if x[0] != ' '])

      elif empty := [v.name for v in newvars if not v.description]:
        state = state.FAIL_VARIABLE_DESCRIPTION
        diff = "\n".join([
            f'----- {readme_rel} variables missing description -----',
            ', '.join(empty),
        ])

      elif empty := [o.name for o in newouts if not o.description]:
        state = state.FAIL_VARIABLE_DESCRIPTION
        diff = "\n".join([
            f'----- {readme_rel} outputs missing description -----',
            ', '.join(empty),
        ])

      elif variables != sorted(variables):
        state = state.FAIL_UNSORTED_VARS
        diff = "\n".join([
            f'----- {readme_rel} variables -----',
            f'variables should be in this order: ',
            ', '.join(sorted(variables)),
        ])

      elif outputs != sorted(outputs):
        state = state.FAIL_UNSORTED_OUTPUTS
        diff = "\n".join([
            f'----- {readme_rel} outputs -----',
            f'outputs should be in this order: ',
            ', '.join(sorted(outputs)),
        ])

      elif nc := [v.name for v in newvars if not v.description.endswith('.')]:
        state = state.FAIL_VARIABLE_PERIOD
        diff = "\n".join([
            f'----- {readme_rel} variable descriptions missing ending period -----',
            ', '.join(nc),
        ])

      elif nc := [o.name for o in newouts if not o.description.endswith('.')]:
        state = state.FAIL_OUTPUT_PERIOD
        diff = "\n".join([
            f'----- {readme_rel} output descriptions missing ending period -----',
            ', '.join(nc),
        ])

      elif no_types := [v.name for v in newvars if not v.type]:
        state = state.FAIL_MISSING_TYPES
        diff = "\n".join([
            f'----- {readme_rel} variables without types -----',
            ', '.join(no_types),
        ])

      yield readme_rel, state, diff


@click.command()
@click.argument('dirs', type=str, nargs=-1)
@click.option('--exclude-file', '-x', multiple=True)
@click.option('--files/--no-files', default=False)
@click.option('--show-diffs/--no-show-diffs', default=False)
@click.option('--show-extra/--no-show-extra', default=False)
@click.option('--show-summary/--no-show-summary', default=True)
def main(dirs, exclude_file=None, files=False, show_diffs=False,
         show_extra=False, show_summary=True):
  'Cycle through modules and ensure READMEs are up-to-date.'
  # print(f'files: {files}, extra: {show_extra}, diffs: {show_diffs}\n')
  errors = []
  for dir_name in dirs:
    result = _check_dir(dir_name, exclude_file, files, show_extra)
    for readme_path, state, diff in result:
      if state.failed:
        errors.append((readme_path, diff))
      if show_summary:
        print(f'[{state.label}] {readme_path}')

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
