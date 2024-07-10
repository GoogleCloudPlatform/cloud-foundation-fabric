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

#
# create_e2e_sandbox.sh <directory>
#
# creates end-to-end tests sandbox in given directory, in result you get:
# 1. <directory>/infra with terraform module applied with all prerequisites provisioned
# 2. <directory> with empty main.tf file, where you can paste any example and manually run any terraform command
#
# You need to have all the environment variables set up only during running of this script. Their values will be
# preserved in terraform.tfvars file, so if you want to destroy / make changes to the infra module, all should work
#
# You can rerun this script on existing directory, this will update all the (terraform) files, but will reuse the existing
# project name and folder name to reduce time to update
#
set -e

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && cd .. && pwd)
DEST=$1
INFRA="${DEST}/infra"
TIMESTAMP=$(date +%s)

mkdir -p "${DEST}" "${INFRA}"

ln -sfT "${DIR}" "${DEST}/fabric"

SETUP_MODULE="${DIR}/tests/examples_e2e/setup_module"
cp "${SETUP_MODULE}/main.tf" "${SETUP_MODULE}/variables.tf" "${SETUP_MODULE}/e2e_tests.tfvars.tftpl" "${INFRA}"

cp "${DIR}/tests/examples/variables.tf" "${DEST}"

if [ ! -f "${INFRA}/randomizer.auto.tfvars" ]; then
	echo "suffix=0" >"${INFRA}/randomizer.auto.tfvars"
	echo "timestamp=${TIMESTAMP}" >>"${INFRA}/randomizer.auto.tfvars"
fi

# TODO correct environment variable prefix
export | sed -e 's/^declare -x //' | grep '^TFTEST_E2E_' | sed -e 's/^TFTEST_E2E_//' >"${INFRA}/terraform.tfvars"
(
	cd "${INFRA}"
	terraform init
	terraform apply -auto-approve
	ln -sfT "${INFRA}/e2e_tests.tfvars" "${DEST}/e2e_tests.auto.tfvars"
)

touch "${DEST}/main.tf"
