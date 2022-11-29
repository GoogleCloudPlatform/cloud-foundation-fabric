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

curl "https://apigee.googleapis.com/v1/organizations/${org_name}/analytics/datastores" \
-X POST \
-H "Content-type:application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-d \
'{
  "displayName": "${datastore_name}",
  "targetType": "gcs",
  "datastoreConfig": {
    "projectId": "${project_id}",
    "bucketName": "${bucket_name}",
    "path": "${path}"
  }
}'
