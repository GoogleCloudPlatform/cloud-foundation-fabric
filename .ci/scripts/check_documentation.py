#!/usr/bin/env python3

# Copyright 2020 Google LLC
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

import sys
from pathlib import Path

BASEDIR = Path(__file__).parents[2]
sys.path.append(str(BASEDIR / "tools"))
import tfdoc


MODULES_DIR = BASEDIR / "modules"


def is_up_to_date(module_path):
  try:
    return tfdoc.is_doc_up_to_date(module_path)
  except (IOError, OSError) as e:
    return False


def main():
  "Cycle through modules and ensure READMEs are up-to-date."
  no_readmes = []
  stale_readmes = []
  for module_path in MODULES_DIR.iterdir():
    module_name = module_path.stem
    if not module_path.is_dir() or module_name.startswith("__"):
      continue
    
    readme = module_path / 'README.md'    
    if not readme.exists():
      no_readmes.append(module_name)
    elif not is_up_to_date(module_path):
      stale_readmes.append(module_name)

  if stale_readmes:
    print('The variables/outputs in the following READMEs are not up-to-date:')
    print('\n'.join(f' - {module}' for module in stale_readmes))
    sys.exit(1)
  if no_readmes:
    print('The following modules are missing a README:')
    print('\n'.join(f' - {module}' for module in no_readmes))
    sys.exit(1)
    

  
if __name__ == '__main__':
  main()
