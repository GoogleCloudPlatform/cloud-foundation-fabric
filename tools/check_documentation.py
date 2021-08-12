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
  MISSING = 1
  OK = 2
  STALE = 3
  UNKNOWN = 4

  def __str__(self):
    return {1: '✗', 2: '✓', 3: '!', 4: '?'}[self.value]


def check_path(pathname):
  path = BASEDIR / pathname
  subpaths = sorted(list(path.iterdir()))
  for subpath in subpaths:
    if not subpath.is_dir():
      continue
    if subpath.stem.startswith('_'):
      continue
    doc = subpath / 'README.md'
    if not doc.exists():
      yield DocState.MISSING, subpath.stem
      continue
    state = tfdoc.check_state(subpath)
    if state is False:
      yield DocState.STALE, subpath.stem
    elif state:
      yield DocState.OK, subpath.stem
    else:
      yield DocState.UNKNOWN, subpath.stem


@click.command()
@click.argument('paths', type=str, nargs=-1)
def main(paths):
  "Cycle through modules and ensure READMEs are up-to-date."
  error = False
  for path in paths:
    print(f'checking {path}')
    for state, name in check_path(path):
      if state in (DocState.MISSING, DocState.STALE):
        error = True
      print(f'  [{state}] {name}')
  if error:
    print('errors were present')
    sys.exit(1)


if __name__ == '__main__':
  main()
