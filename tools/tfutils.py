#!/usr/bin/env python3

# Copyright 2021 Google LLC
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

import pathlib

import click


def main(**kw):
  pass


@click.group()
@click.option('--dry-run', is_flag=True, default=False)
def cli(**kwargs):
  basedir = pathlib.Path(source or '.')
  for f in basedir.glob('**/*.tf'):
    if '.terraform' in f:
      continue
    print(f)


@cli.command()
@click.argument('source', nargs=-1)
@click.option('--from-static/--to-static', default=True)
def mod_source(source=None, from_static=True):
  print('mod_source')
  print(source, from_static)


if __name__ == '__main__':
  cli()
