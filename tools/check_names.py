#!/usr/bin/env python3
# Copyright 2023 Google LLC
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
'Parse names from specific Terraform resources and optionally check length.'

import collections
import enum
import logging
import pathlib
import re

import click

BASEDIR = pathlib.Path(__file__).resolve().parents[1]
LOGGER = logging.getLogger()
MOD_TOKENS = [
    ('NAME', r'\s*module\s*"([^"]+)"\s*\{\s*'),
    ('SOURCE', r'\s*source\s*=\s*"([^"]+)"\s*'),
    ('VALUE', r'\s*name\s*=\s*"([^"]+)"\s*'),
    ('REST', r'(.*)'),
]
MOD = enum.Enum('MOD', ' '.join(name for name, _ in MOD_TOKENS))
MOD_RE = re.compile('|'.join(f'(?:{pattern})' for _, pattern in MOD_TOKENS))
MOD_LIMITS = {'project': 30, 'iam-service-account': 30, 'gcs': 63}

Name = collections.namedtuple('Name', 'source name value length')
Output = collections.namedtuple('Output', 'name length remaining flag')


def get_names(dir_name):
  dir_path = BASEDIR / dir_name
  for tf_path in sorted(dir_path.glob('**/*.tf')):
    if '.terraform' in str(tf_path):
      continue
    LOGGER.debug(f'file {tf_path}')
    doc = tf_path.read_text()
    name = source = None
    for m in MOD_RE.finditer(doc):
      token_type = MOD(m.lastindex)
      if token_type == MOD.REST:
        continue
      value = m.group(m.lastindex).strip()
      LOGGER.debug(f'{token_type}: {value}')
      if token_type == MOD.NAME:
        if name:
          LOGGER.debug(f'module {name} already open ({value})')
        name = value
        source = None
      elif token_type == MOD.SOURCE:
        source = value.split('/')[-1]
        LOGGER.debug(f'{name} {source}')
      elif token_type == MOD.VALUE:
        if name is None or source not in MOD_LIMITS:
          continue
        if '$' in value:
          LOGGER.debug(f'interpolation in {name} ({value}), skipping')
        else:
          yield Name(source, name, value, len(value))
        name = source = None


@click.command()
@click.argument('dirs', type=str, nargs=-1)
# max len(f'{fast prefix max length = 9}-{tenant prefix}') = 11
@click.option('--prefix-length', default=11, type=int)
@click.option('--failed-only', is_flag=True, default=False)
def main(dirs, prefix_length=None, failed_only=False):
  'Parse names in dirs.'
  import json
  logging.basicConfig(level=logging.INFO)
  names = []
  for dir_name in dirs:
    for name in get_names(dir_name):
      names.append(name)
  names.sort()
  source_just = max(len(k) for k in MOD_LIMITS)
  name_just = max(len(n.name) for n in names)
  value_just = max(len(n.value) for n in names)
  errors = []
  output = []
  for name in names:
    name_length = name.length + prefix_length
    remaining = MOD_LIMITS[name.source] - name_length
    if remaining <= 0:
      output.append(Output(name, name_length, remaining, "✗"))
      errors += [f"{name.source}:{name.name}:{name_length}"]
    else:
      output.append(Output(name, name_length, remaining, "✓"))

  output.sort(key=lambda i: i.remaining, reverse=True)
  if failed_only:
    output = [i for i in output if i.flag == "✗"]
  print(f'    {"source".ljust(source_just)} '
        f'{"name".ljust(name_just)} '
        f'{"value".ljust(value_just)} '
        'length  remaining')
  for i in output:
    print(f"[{i.flag}] {i.name.source.ljust(source_just)} "
          f"{i.name.name.ljust(name_just)} "
          f"{i.name.value.ljust(value_just)} "
          f" {i.length}/{MOD_LIMITS[i.name.source]} "
          f"{str(i.remaining).rjust(10)}")
  return 0 if not errors else 1


if __name__ == '__main__':
  main()
