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
'''Check that boilerplate is present in relevant files.

This tools offers a simple way of ensuring that the required boilerplate header
is present in files with specific extensions. Files can be excluded by using a
special comment anywhere in the file.

The interface is purposefully simple and only supports passing one or more
folder paths as arguments, as this tool is designed to be run in CI pipelines
triggered by pull requests.
'''

import os
import re
import sys

import click

_EXCLUDE_DIRS = ('.git', '.terraform')
_EXCLUDE_RE = re.compile(r'# skip boilerplate check')
_MATCH_FILES = ('Dockerfile', '.py', '.sh', '.tf', '.yaml', '.yml')
_MATCH_STRING = (r'^\s*[#\*]\sCopyright [0-9]{4} Google LLC$\s+[#\*]\s+'
                 r'[#\*]\sLicensed under the Apache License, Version 2.0 '
                 r'\(the "License"\);\s+')
_MATCH_RE = re.compile(_MATCH_STRING, re.M)


def check_files(root, files, errors, warnings):
  for fname in files:
    if fname in _MATCH_FILES or os.path.splitext(fname)[1] in _MATCH_FILES:
      fpath = os.path.abspath(os.path.join(root, fname))
      content = open(fpath).read()
      if _EXCLUDE_RE.search(content):
        continue
      try:
        if not _MATCH_RE.search(content):
          errors.append(fpath)
      except (IOError, OSError):
        warnings.append(fpath)


@click.command()
@click.argument('paths', type=str, nargs=-1)
@click.option('--scan-files', default=False, is_flag=True)
def main(paths, scan_files=False):
  "Cycle through files in paths and check for the Apache 2.0 boilerplate."
  errors, warnings = [], []
  if scan_files:
    check_files("./", paths, errors, warnings)
  else:
    for dir in paths:
      for root, dirs, files in os.walk(dir):
        dirs[:] = [d for d in dirs if d not in _EXCLUDE_DIRS]
        check_files(root, files, errors, warnings)

  if warnings:
    print('The following files cannot be accessed:')
    print('\n'.join(' - {}'.format(s) for s in warnings))
  if errors:
    print('The following files are missing the license boilerplate:')
    print('\n'.join(' - {}'.format(s) for s in errors))
    sys.exit(1)


if __name__ == '__main__':
  main()
