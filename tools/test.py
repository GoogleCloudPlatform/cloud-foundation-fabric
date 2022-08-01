#!/usr/bin/env python3
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import collections

URL = 'https://github.com/GoogleCloudPlatform/cloud-foundation-fabric'

ChangelogVersion = collections.namedtuple('ChangelogVersion', 'name date items')


class Error(Exception):
  pass


def changelog_load(path):
  'Parse changelog file and return structured data.'
  versions = []
  try:
    with open(path) as f:
      for l in f.readlines():
        l = l.strip()
        if l.startswith('## '):
          name, _, date = l[3:].partition(' - ')
          versions.append(
              ChangelogVersion(name[1:-1] if name.startswith('[') else None,
                               date, []))
        elif l.startswith('- '):
          if not versions:
            raise Error(f'Item found with no versions: {l}')
          versions[-1].items.append(l[2:])
    return versions
  except (IOError, OSError) as e:
    raise Error(f'Cannot open {path}: {e.args[0]}')


def changelog_dumps(versions, overrides=None):
  'Return formatted changelog from structured data, overriding versions.'
  overrides = overrides or {}
  buffer = [
      ('# Changelog\n\n'
       'All notable changes to this project will be documented in this file.\n')
  ]
  ref_buffer = ['<!-- markdown-link-check-disable -->']
  for i, version in enumerate(versions):
    name, date, items = version
    prev_name = versions[i + 1].name if i + 1 < len(versions) else '0.1'
    if name:
      buffer.append(f'## [{name}] - {date}\n')
      ref_buffer.append(f'[{name}]: {URL}/compare/v{prev_name}...v{name}')
    else:
      buffer.append(f'## [Unreleased]\n')
      ref_buffer.append(f'[Unreleased]: {URL}/compare/v{prev_name}...HEAD')
    for item in overrides.get(name, items):
      buffer.append(f'- {item}')
    buffer.append('')
  return '\n'.join(buffer + [''] + ref_buffer)


print(changelog_dumps(changelog_load('CHANGELOG.md')))
