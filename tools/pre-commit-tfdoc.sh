#!/usr/bin/env bash

# Copyright 2024 Google LLC
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

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

files=("$@")
declare -A directories

for file in "${files[@]}"; do
	dir=$(dirname "${file}")
	if [ -f "${dir}/README.md" ] && [ -f "${dir}/main.tf" ]; then
		directories["${dir}"]=1
	fi
done

for dir in "${!directories[@]}"; do # iterate over keys in directories
	echo python "${SCRIPT_DIR}/tfdoc.py" "${dir}"
	python "${SCRIPT_DIR}/tfdoc.py" "${dir}"
done
