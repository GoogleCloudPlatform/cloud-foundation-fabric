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