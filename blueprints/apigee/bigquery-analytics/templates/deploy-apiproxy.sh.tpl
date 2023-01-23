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
 
#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 ENV_NAME"
    exit 1
fi    

ORG_NAME=${org_name}
ENV_NAME=$1

wget https://github.com/apigee/api-platform-samples/raw/master/sample-proxies/apigee-quickstart/httpbin_rev1_2020_02_02.zip -O apiproxy.zip 

export TOKEN=$(gcloud auth print-access-token)

curl -v -X POST \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type:application/octet-stream" \
-T 'apiproxy.zip' \
"https://apigee.googleapis.com/v1/organizations/$ORG_NAME/apis?name=httpbin&action=import"

curl -v -X POST \
-H "Authorization: Bearer $TOKEN" \
"https://apigee.googleapis.com/v1/organizations/$ORG_NAME/environments/$ENV_NAME/apis/httpbin/revisions/1/deployments"

curl -v \
-H "Authorization: Bearer $TOKEN" \
"https://apigee.googleapis.com/v1/organizations/$ORG_NAME/environments/$ENV_NAME/apis/httpbin/revisions/1/deployments"
