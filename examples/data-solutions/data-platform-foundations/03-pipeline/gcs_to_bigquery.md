# Manual pipeline Example: GCS to Bigquery

In this example we will publish person message in the following format:

```bash
name,surname,1617898199
```

A Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

[TODO] An autorized view will be created in the datamart project to expose the table.
[TODO] Further automation is expected in future.

## Set up the env vars
```bash
export DWH_PROJECT_ID=**dwh_project_id** 
export LANDING_PROJECT_ID=**landing_project_id** 
export TRANSFORMATION_PROJECT_ID=*transformation_project_id*
```

## Create BQ table
Those steps should be done as DWH Service Account.

You can run the command to create a table:

```bash
gcloud --impersonate-service-account=sa-datawh@$DWH_PROJECT_ID.iam.gserviceaccount.com \
alpha bq tables create person \
--project=$DWH_PROJECT_ID --dataset=bq_raw_dataset \
--description "This is a Test Person table" \
--schema name=STRING,surname=STRING,timestamp=TIMESTAMP
```

## Produce CSV data file, JSON schema file and UDF JS file

Those steps should be done as landing Service Account:

Let's now create a series of messages we can use to import:

```bash
for i in {0..10} 
do 
  echo "Lorenzo,Caggioni,$(date +%s)" >> person.csv
done
```

and copy files to the GCS bucket:

```bash
gsutil -i sa-landing@$LANDING_PROJECT_ID.iam.gserviceaccount.com cp person.csv gs://$LANDING_PROJECT_ID-eu-raw-data
```

Let's create the data JSON schema:

```bash
cat <<'EOF' >> person_schema.json
{
  "BigQuery Schema": [
    {
      "name": "name",
      "type": "STRING"
    },
    {
      "name": "surname",
      "type": "STRING"
    },
    {
      "name": "timestamp",
      "type": "TIMESTAMP"
    }
  ]
}
EOF
```

and copy files to the GCS bucket:

```bash
gsutil -i sa-landing@$LANDING_PROJECT_ID.iam.gserviceaccount.com cp person_schema.json gs://$LANDING_PROJECT_ID-eu-data-schema

```

Let's create the data UDF function to transform message data:

```bash
cat <<'EOF' >> person_udf.js
function transform(line) {
  var values = line.split(',');

  var obj = new Object();
  obj.name = values[0];
  obj.surname = values[1];
  obj.timestamp = values[2];
  var jsonString = JSON.stringify(obj);

  return jsonString;
}
EOF
```

and copy files to the GCS bucket:

```bash
gsutil -i sa-landing@$LANDING_PROJECT_ID.iam.gserviceaccount.com cp person_udf.js gs://$LANDING_PROJECT_ID-eu-data-schema
```

if you want to check files copied to GCS, you can use the Transformation service account:

```bash
gsutil -i sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com ls gs://$LANDING_PROJECT_ID-eu-raw-data
gsutil -i sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com ls gs://$LANDING_PROJECT_ID-eu-data-schema

```

## Dataflow

Those steps should be done as transformation Service Account.


Let's than start a Dataflow batch pipeline using a Google provided template using internal only IPs, the created network and subnetwork, the appropriate service account and requested parameters:

```bash
gcloud --impersonate-service-account=sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com dataflow jobs run test_batch_01 \
    --gcs-location gs://dataflow-templates/latest/GCS_Text_to_BigQuery \
    --project $TRANSFORMATION_PROJECT_ID \
    --region europe-west3 \
    --disable-public-ips \
    --network transformation-vpc \
    --subnetwork regions/europe-west3/subnetworks/transformation-subnet \
    --staging-location gs://$TRANSFORMATION_PROJECT_ID-eu-temp \
    --service-account-email sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com \
    --parameters \
javascriptTextTransformFunctionName=transform,\
JSONPath=gs://$LANDING_PROJECT_ID-eu-data-schema/person_schema.json,\
javascriptTextTransformGcsPath=gs://$LANDING_PROJECT_ID-eu-data-schema/person_udf.js,\
inputFilePattern=gs://$LANDING_PROJECT_ID-eu-raw-data/person.csv,\
outputTable=$DWH_PROJECT_ID:bq_raw_dataset.person,\
bigQueryLoadingTemporaryDirectory=gs://$TRANSFORMATION_PROJECT_ID-eu-temp

```