#!/bin/bash

PROJECT_ID=ff-lod
REGION=europe-west1
SERVICE_ACCOUNT=ff-load-df-0@ff-lod.iam.gserviceaccount.com

CSV_FILE=gs://ff-drp-cs-0/customers.csv
JSON_SCHEMA=gs://ff-orc-cs-0/customers_schema.json
OUTPUT_TABLE=ff-dwh-lnd.ff_dwh_lnd_bq_0.customers
TEMPLATE_PATH=gs://ff-orc-cs-df-template/csv2bq.json


gcloud dataflow flex-template run "files2bq-test0-file-loads-`date +%Y%m%d-%H%M%S`" \
    --template-file-gcs-location $TEMPLATE_PATH \
    --parameters temp_location="gs://ff-load-cs-0/tmp" \
    --parameters staging_location="gs://ff-load-cs-0/stage" \
    --parameters csv_file=$CSV_FILE \
    --parameters json_schema=$JSON_SCHEMA\
    --parameters output_table=$OUTPUT_TABLE \
    --region $REGION \
    --project $PROJECT_ID \
    --subnetwork="regions/europe-west1/subnetworks/default" \
    --service-account-email=$SERVICE_ACCOUNT
