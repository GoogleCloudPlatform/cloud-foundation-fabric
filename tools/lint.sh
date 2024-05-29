#!/bin/bash

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

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo -- Boilerplate check --
python3 tools/check_boilerplate.py $PWD

echo -- Terraform format --
terraform fmt -recursive -check -diff $PWD

echo -- READMEs --
python3 tools/check_documentation.py --no-show-summary modules fast blueprints

echo -- Links --
python3 tools/check_links.py --no-show-summary $PWD

echo -- FAST Names --
python3 tools/check_names.py --prefix-length=10 --failed-only fast/stages

echo -- Python formatting --
yapf -p -d -r \
     tools/*.py \
     blueprints

echo -- Blueprint metadata --
python3 tools/validate_metadata.py -v blueprints --verbose --failed-only

echo -- Version checks --
find . -type f -name 'versions.tf' -exec diff -ub default-versions.tf {} \;
