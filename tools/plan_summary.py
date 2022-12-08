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

import click
import sys
import yaml

from pathlib import Path

BASEDIR = Path(__file__).parents[1]
sys.path.append(str(BASEDIR / 'tests'))

import fixtures


@click.command()
@click.argument('module', type=click.Path(), nargs=1)
@click.argument('tfvars', type=click.Path(exists=True), nargs=-1)
def main(module, tfvars):
  module = BASEDIR / module
  summary = fixtures.plan_summary(module, Path(), tfvars)
  print(yaml.dump({'values': summary.values}))
  print(yaml.dump({'counts': summary.counts}))
  outputs = {
      k: v.get('value', '__missing__') for k, v in summary.outputs.items()
  }
  print(yaml.dump({'outputs': outputs}))


if __name__ == '__main__':
  main()
