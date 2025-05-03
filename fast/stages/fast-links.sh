#!/bin/bash
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

if [ $# -eq 0 ]; then
  echo "Error: no folder or GCS bucket specified. Use -h or --help for usage."
  exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<END
Create commands to initialize stage provider and tfvars files. Use this script
from inside a stage folder.

Usage with GCS output files bucket:
  fast-links.sh GCS_BUCKET_URI

Usage with local output files folder:
  fast-links.sh FOLDER_PATH

Point path/GCS URI to the tenant folder in tenant mode:
  fast-links.sh FOLDER_PATH/TENANT_SHORTNAME
END
  exit 0
fi

if [[ "$1" == "gs://"* ]]; then
  CMD="gcloud storage cp $1"
  CP_CMD=$CMD
elif [ ! -d "$1" ]; then
  echo "folder $1 not found"
  exit 1
else
  CMD="ln -s $1"
  CP_CMD="cp $1"
fi

if [ ! -f .fast-stage.env ]; then
  echo "this folder does not look like a FAST stage"
  exit 1
fi

set -a && source .fast-stage.env && set +a

echo -e "# File linking commands for $FAST_STAGE_DESCRIPTION stage\n"

echo "# provider file"
if [[ ! -z ${FAST_STAGE_PROVIDERS+x} ]]; then
  echo "$CMD/providers/${FAST_STAGE_LEVEL}-${FAST_STAGE_PROVIDERS}-providers.tf ./"
else
  echo "$CMD/providers/${FAST_STAGE_LEVEL}-${FAST_STAGE_NAME}-providers.tf ./"
fi

if [[ ! -z ${FAST_STAGE_DEPS+x} ]]; then
  echo -e "\n# input files from other stages"
  for f in $FAST_STAGE_DEPS; do
    echo "$CMD/tfvars/$f.auto.tfvars.json ./"
  done
fi

echo -e "\n# conventional location for this stage terraform.tfvars (manually managed)"
echo "$CMD/${FAST_STAGE_LEVEL}-${FAST_STAGE_NAME}.auto.tfvars ./"

if [[ ! -z ${FAST_STAGE_OPTIONAL+x} ]]; then
  echo -e "\n# optional files"
  for f in $FAST_STAGE_OPTIONAL; do
    echo "$CMD/tfvars/$f.auto.tfvars.json ./"
  done
fi

echo
