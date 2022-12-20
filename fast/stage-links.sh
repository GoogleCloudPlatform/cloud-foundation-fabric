#!/bin/bash
# Copyright 2022 Google LLC
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
  echo "pass one argument with the path to the output files folder or GCS bucket"
  exit 1
fi

if [[ "$1" == "gs://"* ]]; then
  CMD="gcloud alpha storage cp $1"
elif [ ! -d "$1" ]; then
  echo "folder $1 not found"
  exit 1
else
  CMD="ln -s $1"
fi

STAGE_NAME=$(basename "$(pwd)")

case $STAGE_NAME in

"0-bootstrap")
  FILES="providers/multitenant/${STAGE_NAME}-providers.tf"
  ;;
"0-bootstrap-tenant")
  FILES="providers/multitenant/0-boostrap-providers.tf
  tfvars/globals.auto.tfvars.json
  tfvars/0-bootstrap.auto.tfvars.json
  tfvars/1-resman.auto.tfvars.json"
  ;;
"0-bootstrap-multitenant")
  FILES="providers/multitenant/0-boostrap-providers.tf
  tfvars/globals.auto.tfvars.json
  tfvars/0-bootstrap.auto.tfvars.json
  tfvars/1-resman.auto.tfvars.json"
  ;;
"1-resman")
  FILES="providers/multitenant/${STAGE_NAME}-providers.tf
  tfvars/globals.auto.tfvars.json
  tfvars/0-bootstrap.auto.tfvars.json"
  ;;
"2-"*)
  FILES="providers/multitenant/${STAGE_NAME}-providers.tf
  tfvars/globals.auto.tfvars.json
  tfvars/0-bootstrap.auto.tfvars.json
  tfvars/1-resman.auto.tfvars.json"
  ;;
*)
  # check for a "dev" stage 3
  STAGE_PARENT=$(basename $(dirname "$(pwd)"))
  if [[ "$STAGE_PARENT" == "3-"* ]]; then
    FILES="providers/${STAGE_PARENT}-providers.tf
    tfvars/globals.auto.tfvars.json
    tfvars/0-bootstrap.auto.tfvars.json
    tfvars/1-resman.auto.tfvars.json
    tfvars/2-networking.auto.tfvars.json
    tfvars/2-security.auto.tfvars.json"
  else
    echo "stage '$STAGE_NAME' not found"
  fi
  ;;

esac

for f in $FILES; do
  echo "$CMD/$f ./"
done
