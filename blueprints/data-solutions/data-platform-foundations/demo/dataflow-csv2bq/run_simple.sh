#!/bin/bash

PROJECT_ID=ff-lod
REGION=europe-west1
SERVICE_ACCOUNT=ff-load-df-0@ff-lod.iam.gserviceaccount.com

CSV_FILE=gs://ff-drp-cs-0/customers.csv
JSON_SCHEMA=gs://ff-orc-cs-0/customers_schema.json
OUTPUT_TABLE=ff-dwh-lnd.ff_dwh_lnd_bq_0.customers

# Run the pipeline
python src/csv2bq.py \
    --runner="DataflowRunner" \
    --project=$PROJECT_ID \
    --region=$REGION \
    --subnetwork="regions/europe-west1/subnetworks/default" \
    --service_account_email=$SERVICE_ACCOUNT \
    --temp_location="gs://ff-load-cs-0/tmp" \
    --csv_file=$CSV_FILE \
    --json_schema=$JSON_SCHEMA $PIPELINE_OPTIONS \
    --output_table=$OUTPUT_TABLE
