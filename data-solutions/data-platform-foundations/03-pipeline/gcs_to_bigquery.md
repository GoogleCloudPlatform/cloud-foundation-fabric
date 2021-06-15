# Manual pipeline Example: GCS to Bigquery

In this example we will publish person message in the following format:

```bash
Lorenzo,Caggioni,1617898199
```

a Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

[TODO] An autorized view will be created in the datamart project to expose the table.
[TODO] Remove hardcoded 'lcaggio' variables and made ENV variable for it.
[TODO] Further automation is expected in future.

Create and download keys for Service accounts you created.

## Create BQ table

Those steps should be done as Transformation Service Account:

```bash
gcloud auth activate-service-account sa-dwh@dwh-lc01.iam.gserviceaccount.com --key-file=sa-dwh.json --project=dwh-lc01
```

and you can run the command to create a table:

```bash
bq mk \
-t \
--description "This is a Test Person table" \
dwh-lc01:bq_raw_dataset.person \
name:STRING,surname:STRING,timestamp:TIMESTAMP
```

## Produce CSV data file, JSON schema file and UDF JS file

Those steps should be done as landing Service Account:

```bash
gcloud auth activate-service-account sa-landing@landing-lc01.iam.gserviceaccount.com --key-file=sa-landing.json --project=landing-lc01
```

Let's now create a series of messages we can use to import:

```bash
for i in {0..10} 
do 
  echo "Lorenzo,Caggioni,$(date +%s)" >> person.csv
done
```

and copy files to the GCS bucket:

```bash
gsutil cp person.csv gs://landing-lc01-eu-raw-data
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
gsutil cp person_schema.json gs://landing-lc01-eu-data-schema
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
gsutil cp person_udf.js gs://landing-lc01-eu-data-schema
```

if you want to check files copied to GCS, you can use the Transformation service account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

and read a message (message won't be acked and will stay in the subscription):

```bash
gsutil ls gs://landing-lc01-eu-raw-data
gsutil ls gs://landing-lc01-eu-data-schema
```

## Dataflow

Those steps should be done as transformation Service Account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

Let's than start a Dataflwo batch pipeline using a Google provided template using internal only IPs, the created network and subnetwork, the appropriate service account and requested parameters:

```bash
gcloud dataflow jobs run test_batch_lcaggio01 \
    --gcs-location gs://dataflow-templates/latest/GCS_Text_to_BigQuery \
    --project transformation-lc01 \
    --region europe-west3 \
    --disable-public-ips \
    --network transformation-vpc \
    --subnetwork regions/europe-west3/subnetworks/transformation-subnet \
    --staging-location gs://transformation-lc01-eu-temp \
    --service-account-email sa-transformation@transformation-lc01.iam.gserviceaccount.com \
    --parameters \
javascriptTextTransformFunctionName=transform,\
JSONPath=gs://landing-lc01-eu-data-schema/person_schema.json,\
javascriptTextTransformGcsPath=gs://landing-lc01-eu-data-schema/person_udf.js,\
inputFilePattern=gs://landing-lc01-eu-raw-data/person.csv,\
outputTable=dwh-lc01:bq_raw_dataset.person,\
bigQueryLoadingTemporaryDirectory=gs://transformation-lc01-eu-temp
```
