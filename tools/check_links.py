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

'''Recursively check link destination validity in README files.

This tool recursively checks that local links in README files point to valid
destinations. Its main use is in CI pipelines triggered by pull requests.
'''


import collections
import pathlib
import urllib.parse

import click
import marko


BASEDIR = pathlib.Path(__file__).resolve().parents[1]
DOC = collections.namedtuple('DOC', 'path relpath links')
LINK = collections.namedtuple('LINK', 'dest valid')


def check_docs(dir_name):
  'Traverse dir_name and check links in README.md files.'
  dir_path = BASEDIR / dir_name
  for readme_path in sorted(dir_path.glob('**/README.md')):
    if '.terraform' in str(readme_path) or '.pytest' in str(readme_path):
      continue
    links = []
    for el in marko.parser.Parser().parse(readme_path.read_text()).children:
      if not isinstance(el, marko.block.Paragraph):
        continue
      for subel in el.children:
        if not isinstance(subel, marko.inline.Link):
          continue
        link_valid = None
        url = urllib.parse.urlparse(subel.dest)
        if url.scheme:
          link_valid = True
        else:
          link_valid = (readme_path.parent / url.path).exists()
        links.append(LINK(subel.dest, link_valid))
    yield DOC(readme_path, str(readme_path.relative_to(dir_path)), links)


@ click.command()
@ click.argument('dirs', type=str, nargs=-1)
def main(dirs):
  'Check links in README files contained in dirs.'
  errors = 0
  for dir_name in dirs:
    print(f'----- {dir_name} -----')
    for doc in check_docs(dir_name):
      state = '✓' if all(l.valid for l in doc.links) else '✗'
      print(f'[{state}] {doc.relpath} ({len(doc.links)})')
      if state == '✗':
        errors += 1
        for l in doc.links:
          if not l.valid:
            print(f'  {l.dest}')
  if errors:
    raise SystemExit('Errors found.')


if __name__ == '__main__':
  main()
