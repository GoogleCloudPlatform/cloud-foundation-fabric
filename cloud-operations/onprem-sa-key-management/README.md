# Generationg and uploading public keys for a service accounts

This example shows how to manage IAM Service Account Keys by generating a key pair and uploading public keys to GCP. 

By generating a key inside a `box` where the key is intended to be used we AVOID:
 - [passing keys between users](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys#pass-between-users) or systems
 - having SA key stored in the terraform state (only public part in the state)
 - having SA key with no expiration period

TODO (averbukh)
## Running the example 
# cleaning up example keys
- rm -f /public-keys/data-uploader/
- rm -f /public-keys/prisma-security/

# generate your keys
- mkdir keys && cd keys
- openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -keyout data_uploader_private_key.pem \
    -out ../public-keys/data-uploader/public_key.pem \
    -subj "/CN=unused"
- openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -keyout prisma_security_private_key.pem \
    -out ../public-keys/prisma-security/public_key.pem \
    -subj "/CN=unused"

- cd ..
- terraform init
- terraform apply -var project_id=$GOOGLE_CLOUD_PROJECT

- terraform show -json | jq '.values.outputs."data-uploader-credentials".value."public_key.pem" | fromjson' > data-uploader.json
- terraform show -json | jq '.values.outputs."prisma-security-credentials".value."public_key.pem" | fromjson' > prisma-security.json

- contents=$(jq --arg key "$(cat keys/data_uploader_private_key.pem)" '.private_key=$key' data-uploader.json) && echo "$contents" > data-uploader.json
- contents=$(jq --arg key "$(cat keys/prisma_security_private_key.pem)" '.private_key=$key' prisma-security.json) && echo "$contents" > prisma-security.json

- gcloud auth activate-service-account --key-file prisma-security.json
- gcloud auth activate-service-account --key-file data-uploader.json

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| *project_create* | Create project instead ofusing an existing one. | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| data-uploader-credentials | Data Uploader SA json key templates. |  |
| prisma-security-credentials | Prisma Security SA json key templates. |  |
<!-- END TFDOC -->
