#!/bin/sh

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

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
TFDOC_CMD="${SCRIPT_DIR}/tfdoc.py"
CHECKDOC_CMD="${SCRIPT_DIR}/check_documentation.py"

for file in "$@"; do
	if [ -d "${file}" ]; then
		dir="${file}"
	else
		dir=$(dirname "${file}")
	fi
	if [ -f "${dir}/README.md" ] && [ -f "${dir}/main.tf" ]; then
		echo "${dir}"
	fi

done | sort | uniq | xargs -I {} /bin/sh -c "echo python \"${TFDOC_CMD}\" {} ; python \"${TFDOC_CMD}\" {} ; echo python \"${CHECKDOC_CMD}\" {} ; python \"${CHECKDOC_CMD}\" {}"
