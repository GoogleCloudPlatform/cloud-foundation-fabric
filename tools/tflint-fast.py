#!/usr/bin/env python3

# Copyright 2024 Google LLC
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
import glob
import subprocess
import yaml

from pathlib import Path


@click.command()
def main():
  ret = 0
  for tftest_path in sorted(
      glob.glob("tests/fast/**/tftest.yaml", recursive=True)):
    with open(tftest_path, "r") as f:
      tftest = yaml.safe_load(f)
    module_path = Path(tftest['module'])
    var_path = (Path(tftest_path).parent / "simple.tfvars")
    if var_path.exists():
      args = [
          "tflint", "--chdir",
          str(module_path.absolute()), "--var-file",
          str(var_path.absolute())
      ]
      print(" ".join(args))
      ret |= subprocess.run(args).returncode
    else:
      print(f'Skipping stage: {tftest_path} as no simple.tfvars found there')
  # end for
  exit(ret)


if __name__ == '__main__':
  main()
