

################################# Quickstart #################################

- terraform init
- terraform apply -var project_id=$GOOGLE_CLOUD_PROJECT \
  -var --organization=ORGANIZATION_ID \
  -var --bq-table=TABLE_NAME \
  -var --bq-project=PROJECT_ID \
  -var --bq-dataset=DATASET_NAME

Refer to the README.md file for more info.

