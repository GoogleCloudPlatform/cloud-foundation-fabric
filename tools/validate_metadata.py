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
'''Validate a YAML file against the standard blueprint metadata schema[1]

[1] https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/blob/master/cli/bpmetadata/schema/bpmetadataschema.json
'''

import enum
import json
import sys
from dataclasses import dataclass
from pathlib import Path

import click
import jsonschema
import yaml

SCHEMA_PATH = Path(__file__).parent / 'bpmetadataschema.json'


class State(enum.Enum):
  INVALID: int = 0
  OK: int = 1


@dataclass
class ValidationResult:
  state: State
  errors: dict[str, str]


def _validate(path: Path, validator) -> ValidationResult:
  with open(path) as f:
    metadata = yaml.safe_load(f)

  errors = {
      error.json_path: error.message
      for error in validator.iter_errors(metadata)
  }

  state = State.OK if not errors else State.INVALID
  return ValidationResult(state=state, errors=errors)


@click.command()
@click.argument('dirs', type=click.Path(exists=True, file_okay=False), nargs=-1)
@click.option('-v', '--verbose', is_flag=True, default=False,
              help='Print additional validation details.')
@click.option('--failed-only', is_flag=True, default=False)
def main(dirs: list[str], verbose: bool, failed_only=False) -> int:
  instances = set()
  for dir_name in dirs:
    instances |= set(Path(dir_name).glob("**/metadata.yaml"))

  with open(SCHEMA_PATH) as f:
    schema = json.load(f)
  validator = jsonschema.validators.Draft202012Validator(schema)

  failed_files = {}
  for instance in instances:
    result = _validate(instance, validator)
    if result.state == State.OK:
      if not failed_only:
        print(f'[✓] {instance}')
    else:
      print(f'[✗] {instance}')
      failed_files[instance] = result.errors

  if verbose:
    for file_path, errors in failed_files.items():
      print(f"\n====== {file_path!s} ======")
      for path, message in errors.items():
        print(f"{path}: {message}")

  return 0 if not failed_files else 1


if __name__ == '__main__':
  sys.exit(main())
