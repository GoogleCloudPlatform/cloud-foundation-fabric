#!/bin/bash

# Copyright 2026 Google LLC
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

# shellcheck disable=SC2034
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
STATUS=0

run_check() {
  local label=$1
  shift
  echo "-- ${label} --"
  if ! "$@"; then
    STATUS=1
  fi
}

run_check "Boilerplate check" python3 tools/check_boilerplate.py "$PWD"
run_check "Terraform format" terraform fmt -recursive -check -diff "$PWD"

if command -v tflint >/dev/null 2>&1; then
  run_check "TFLint modules" bash -c 'cd modules && tflint --recursive --config="$1/.tflint.hcl" -f compact' _ "$PWD"
  run_check "TFLint FAST" python3 tools/tflint-fast.py
else
  echo "-- TFLint (skipped: tflint not found in PATH) --"
fi

run_check "READMEs" python3 tools/check_documentation.py --no-show-summary modules fast
run_check "Schema docs" python3 tools/check_schema_docs.py --no-show-summary modules fast
run_check "Links" python3 tools/check_links.py --no-show-summary "$PWD"
run_check "FAST Names" python3 tools/check_names.py --prefix-length=10 --failed-only fast/stages
run_check "YAML schemas" python3 tools/check_yaml_schema.py modules fast
run_check "Duplicate files" python3 tools/duplicate-diff.py
run_check "YAML linting" yamllint -c .yamllint --no-warnings .
run_check "Python formatting" yapf -p -d -r tools/*.py

echo "-- Version checks --"
for engine in tf tofu; do
  while IFS= read -r -d '' f; do
    if ! diff -I '[[:space:]]*module_name' -ub "default-versions.${engine}" "$f"; then
      STATUS=1
    fi
  done < <(find . -type f -name "versions.${engine}" -print0)
done

if command -v codespell >/dev/null 2>&1; then
  run_check "Spelling (codespell)" codespell --skip=".git,*.pem,requirements.txt,*.excalidraw,package-lock.json,go.sum,CHANGELOG.md" .
else
  echo "-- Spelling (skipped: codespell not found in PATH) --"
fi

exit "$STATUS"
