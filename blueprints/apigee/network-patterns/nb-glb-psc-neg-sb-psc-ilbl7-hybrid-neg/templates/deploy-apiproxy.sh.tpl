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
 
#!/bin/bash

ORGANIZATION=${organization}
ENVIRONMENT=${environment}

export TOKEN=$(gcloud auth print-access-token)

curl -v -X POST \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type:application/octet-stream" \
-T 'bundle.zip' \
"https://apigee.googleapis.com/v1/organizations/$ORGANIZATION/apis?name=test&action=import"

curl -v -X POST \
-H "Authorization: Bearer $TOKEN" \
"https://apigee.googleapis.com/v1/organizations/$ORGANIZATION/environments/$ENVIRONMENT/apis/test/revisions/1/deployments"

curl -v \
-H "Authorization: Bearer $TOKEN" \
"https://apigee.googleapis.com/v1/organizations/$ORGANIZATION/environments/$ENVIRONMENT/apis/test/revisions/1/deployments"
