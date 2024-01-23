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
'''Validate YaML document against yamale schemas.
Fast includes YaML driven resource factories, along with their schemas which 
are available at `fast/assets/schemas`.

An arbitrary number of files and directories can be validated against a given
schema via options (--file and --directory, optionally --recursive).
'''

import glob
import os

import click
import yamale


@click.command()
@click.argument('schema', type=click.Path(exists=True))
@click.option('--directory', multiple=True,
              type=click.Path(exists=True, file_okay=False, dir_okay=True))
@click.option('--file', multiple=True,
              type=click.Path(exists=True, file_okay=True, dir_okay=False))
@click.option('--recursive', is_flag=True, default=False)
@click.option('--quiet', is_flag=True, default=False)
def main(directory=None, file=None, schema=None, recursive=False, quiet=False):
  'Program entry point.'

  yamale_schema = yamale.make_schema(schema)
  search = "**/*.yaml" if recursive else "*.yaml"
  has_errors = []

  files = list(file)
  for d in directory:
    files = files + glob.glob(os.path.join(d, search), recursive=recursive)

  for document in files:
    yamale_data = yamale.make_data(document)
    try:
      yamale.validate(yamale_schema, yamale_data)
      if quiet:
        pass
      else:
        print(f'✅  {document} -> {os.path.basename(schema)}')
    except ValueError as e:
      has_errors.append(document)
      print(e)
      print(f'❌ {document} -> {os.path.basename(schema)}')

  if len(has_errors) > 0:
    raise SystemExit(f"❌ Errors found in {len(has_errors)} documents.")


if __name__ == '__main__':
  main()
