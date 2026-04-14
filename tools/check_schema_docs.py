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
'''Recursively check freshness of generated markdown from JSON schemas.

This tool recursively checks that the markdown files generated from JSON schemas
match what is generated at runtime by schema_docs based on current sources.
'''

import difflib
import enum
import json
import logging
import pathlib
import sys

import click

try:
  import schema_docs
except ImportError:
  sys.path.append(str(pathlib.Path(__file__).resolve().parent))
  import schema_docs

BASEDIR = pathlib.Path(__file__).resolve().parents[1]


class State(enum.IntEnum):
  SKIP = enum.auto()
  OK = enum.auto()
  FAIL_STALE_DOC = enum.auto()
  FAIL_MISSING_DOC = enum.auto()
  FAIL_ORPHAN_DOC = enum.auto()

  @property
  def failed(self):
    return self.value > State.OK

  @property
  def label(self):
    return {
        State.SKIP: '  ',
        State.OK: '✓ ',
        State.FAIL_STALE_DOC: '✗D',
        State.FAIL_MISSING_DOC: '✗M',
        State.FAIL_ORPHAN_DOC: '✗O',
    }[self.value]


def _check_dir(dir_name):
  'Invoke schema_docs on folder, using the relevant options.'
  dir_path = BASEDIR / dir_name
  existing_docs = set(
      p for p in dir_path.glob('**/*.schema.md') if '.terraform' not in str(p))

  for schema_path in sorted(dir_path.glob('**/*.schema.json')):
    if '.terraform' in str(schema_path):
      continue

    diff = None
    schema_rel = str(schema_path.relative_to(BASEDIR))
    doc_path = schema_path.with_suffix('.md')
    existing_docs.discard(doc_path)

    try:
      schema = json.load(schema_path.open())
    except json.JSONDecodeError as e:
      raise SystemExit(f'error decoding file {schema_path}: {e.args[0]}')

    # schema_docs uses logging.DEBUG heavily
    logging.getLogger().setLevel(logging.CRITICAL)

    tree = schema_docs.parse_node(schema)
    props, defs = schema_docs.render_node(tree)
    doc = schema_docs.DOC.format(title=schema.get('title'), properties=props,
                                 definitions=defs or '')
    new_doc_content = f'{doc}\n'

    state = State.OK

    if not doc_path.exists():
      state = State.FAIL_MISSING_DOC
      diff = f'----- {schema_rel} missing doc -----\nFile {doc_path.relative_to(BASEDIR)} does not exist.'
    else:
      current_doc_content = doc_path.read_text()
      if new_doc_content != current_doc_content:
        state = State.FAIL_STALE_DOC
        header = f'----- {schema_rel} diff -----\n'
        ndiff = difflib.ndiff(current_doc_content.splitlines(keepends=True),
                              new_doc_content.splitlines(keepends=True))
        diff = ''.join([header] + [x for x in ndiff if x[0] != ' '])

    yield schema_rel, state, diff

  for doc_path in sorted(existing_docs):
    doc_rel = str(doc_path.relative_to(BASEDIR))
    diff = f'----- {doc_rel} orphan doc -----\nFile {doc_rel} does not have a matching schema.'
    yield doc_rel, State.FAIL_ORPHAN_DOC, diff


@click.command()
@click.argument('dirs', type=str, nargs=-1)
@click.option('--show-diffs/--no-show-diffs', default=False)
@click.option('--show-summary/--no-show-summary', default=True)
def main(dirs, show_diffs=False, show_summary=True):
  'Cycle through modules and ensure schema docs are up-to-date.'
  errors = []
  for dir_name in dirs:
    result = _check_dir(dir_name)
    for schema_path, state, diff in result:
      if state.failed:
        errors.append((schema_path, diff))
      if show_summary:
        print(f'[{state.label}] {schema_path}')

  if errors:
    print('\nErrored schemas:\n')
    for e in errors:
      module, diff = e
      print(f'- {module}')
      if show_diffs:
        print()
        print(''.join(diff))
        print()
    print()
    raise SystemExit('Errors found.')


if __name__ == '__main__':
  main()
