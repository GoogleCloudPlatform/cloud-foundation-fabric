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
'''Recursively check link destination validity in Markdown files.

This tool recursively checks that local links in Markdown files point to valid
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
OBJS_EXPAND = (marko.block.List, marko.block.ListItem, marko.block.Paragraph)
OBJS_LINK = marko.inline.Link


def check_link(link, readme_path):
  'Checks if a link element has a valid destination.'
  link_valid = None
  url = urllib.parse.urlparse(link.dest)
  if url.scheme:
    # TODO: worth checking if the call returns 404, 403, 500
    link_valid = True
  else:
    link_valid = (readme_path.parent / url.path).exists()
  return LINK(link.dest, link_valid)


def check_elements(elements, readme_path):
  'Recursively finds and checks links in a list of elements.'
  if len(elements) == 0:
    return []

  el = elements[0]

  # If there is one element, check the link,
  # expand it (if possible), return [] otherwise
  if len(elements) == 1:
    if isinstance(el, OBJS_LINK):
      return [check_link(el, readme_path)]
    if isinstance(el, OBJS_EXPAND):
      return check_elements(el.children, readme_path)
    return []

  # If there is more than one element call recursively:
  # concatenate call on the first element and call on all other elements
  if len(elements) > 1:
    link_in_first_element = check_elements([el], readme_path)
    link_in_other_elements = check_elements(elements[1:len(elements)],
                                            readme_path)
    return link_in_first_element + link_in_other_elements


def check_docs(dir_name):
  'Traverses dir_name and checks for all Markdown files.'
  dir_path = BASEDIR / dir_name
  for readme_path in sorted(dir_path.glob('**/*.md')):
    if '.terraform' in str(readme_path) or '.pytest' in str(readme_path):
      continue
    els = marko.parser.Parser().parse(readme_path.read_text()).children
    links = check_elements(els, readme_path)
    yield DOC(readme_path, str(readme_path.relative_to(dir_path)), links)


@click.command()
@click.argument('dirs', type=str, nargs=-1)
def main(dirs):
  'Checks links in Markdown files contained in dirs.'
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
