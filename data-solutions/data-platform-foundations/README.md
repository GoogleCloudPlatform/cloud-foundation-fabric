# Data Platform Foundations

## General

The goal of this project is to design & build a robust and flexible Foundational Data Platform on GCP that provides opinionated defaults while allowing customers to build and scale out data pipelines quickly and reliably.

There are three provisioning workflows to enable an end to end Foundational Data Platform along with Data Pipelines on top of it. This is represented in the diagram below.

![Three Main Workflows](../img/three_main_workflows.png)

In this example we will create the infrastructure needed for the foundational build.

Since this example is intended for the data infra engineers we do expect that an initial organization / folder and service account with owner privileges will be pre-created and provided as variables.

This example assume the next items were already created and provided:

- Organization / folder
- Terraform runner Service account with owner permissions on the above organization / folder

## Managed resources and services

This sample creates several distinct groups of resources:

### Projects

- [x] Common services
- [x] Landing
- [x] Orchestration & Transformation
- [x] DWH
- [x] Datamart

### Resources per project

- Common
  - [x] One service account under Common services to control all projects
- Landing
  - [x] GCS
  - [x] Pub/Sub
- Orchestration & Transformation
  - [x] Dataflow
- DWH
  - [x] Bigquery (L0/1/2)
  - [x] GCS
- Datamart
  - [x] Bigquery (views/table)
  - [x] GCS
  - [ ] BigTable

The architecture uses:

- [Google Cloud Storage](https://cloud.google.com/storage)
- [Google Pub/Sub](https://cloud.google.com/pubsub)
- [Google Cloud Dataflow](https://cloud.google.com/dataflow/)
- [Google BigQuery](https://cloud.google.com/bigquery/)

## Manageing Multiple Environments

Terraform is a great tool for provisioning immutable infrastructure.
There are several ways to get Terraform to provision different environments using one repo. Here I’m going to use the most basic and naive method - the State separation.
State separation signals more mature usage of Terraform but with additional maturity comes additional complexity.
There are two primary methods to separate state between environments: directories and workspaces. I’m going to use the directory method.

For this example I’ll assume we have 3 environments:

- Dev
- QA
- Prod

```bash
export data_platform_folder="dpm"
export my_ldap=<YOUR_LDAP>

mkdir ${data_platform_folder}
cd ${data_platform_folder}

git clone ssh://${my_ldap}@google.com@source.developers.google.com:2022/p/data-platform-foundations/r/data-platform-foundations dev

git clone ssh:///${my_ldap}@google.com@source.developers.google.com:2022/p/data-platform-foundations/r/data-platform-foundations prod

git clone ssh:///${my_ldap}@google.com@source.developers.google.com:2022/p/data-platform-foundations/r/data-platform-foundations qa
```

(make sure you entered the right val for **my_ldap**)

Now you have a directory per environment in which you can do all the needed configurations (tfvars files) and provision it.

## TODO list

| Description | Priority (1:High - 5:Low ) | Status | Remarks |
|-------------|----------|:------:|---------|
| DLP best practices in the pipeline | 2 | Not Started |   |
| KMS support (CMEK) | 2 | Not Started |   |
| VPC-SC | 3 | Not Started |   |
| Add Composer with a static DAG running the example | 3 | Not Started |   |
| Integrate [CI/CD composer data processing workflow framework](https://github.com/jaketf/ci-cd-for-data-processing-workflow) | 3 | Not Started |   |
| Schema changes, how to handle | 4 | Not Started |   |
| Data lineage | 4 | Not Started |   |
| Data quality checks | 4 | Not Started |   |
| Shared-VPC | 5 | Not Started |   |
| Logging & monitoring | TBD | Not Started |   |
| Orcestration for ingestion pipeline (just in the readme) | TBD | Not Started |   |

## Manual pipeline Example: PubSub to Bigquery

Once you deployed projects (step 1) and resources (step 2) you can use it to run your data pipeline. As first example below you can find set of manual steps for an end to end example.

In this example we will publish person message in the following format:

```txt
name: Lorenzo
surname: Caggioni
timestamp: 1617898199
```

a Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

An autorized view will be created in the datamart project to expose the table.

[TODO] Remove hardcoded 'lcaggio' variables and made ENV variable for it.
[TODO] Further automation is expected in future.

Create and download keys for Service accounts you created, be sure to have `iam.serviceAccountKeys.create` permission on projects or at folder level.

```bash
gcloud iam service-accounts keys create sa-landing.json --iam-account=sa-landing@landing-lc01.iam.gserviceaccount.com
gcloud iam service-accounts keys create sa-transformation.json --iam-account=sa-transformation@transformation-lc01.iam.gserviceaccount.com
gcloud iam service-accounts keys create sa-dwh.json --iam-account=sa-dwh@dwh-lc01.iam.gserviceaccount.com
```

### Create BQ table

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

### Produce PubSub messages

Those steps should be done as landing Service Account:

```bash
gcloud auth activate-service-account sa-landing@landing-lc01.iam.gserviceaccount.com --key-file=sa-landing.json --project=landing-lc01
```

and let's now create a series of messages we can use to import:

```bash
for i in {0..10} 
do 
  gcloud pubsub topics publish projects/landing-lc01/topics/landing-1 --message="{\"name\": \"Lorenzo\", \"surname\": \"Caggioni\", \"timestamp\": \"$(date +%s)\"}"
done
```

if you want to check messages published, you can use the Transformation service account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

and read a message (message won't be acked and will stay in the subscription):

```bash
gcloud pubsub subscriptions pull projects/landing-lc01/subscriptions/sub1
```

### Dataflow

Those steps should be done as transformation Service Account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

Let's than start a Dataflwo streaming pipeline using a Google provided template using internal only IPs, the created network and subnetwork, the appropriate service account and requested parameters:

```bash
gcloud dataflow jobs run test_lcaggio01 \
    --gcs-location gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
    --project transformation-lc01 \
    --region europe-west3 \
    --disable-public-ips \
    --network transformation-vpc \
    --subnetwork regions/europe-west3/subnetworks/transformation-subnet \
    --staging-location gs://transformation-lc01-eu-temp \
    --service-account-email sa-transformation@transformation-lc01.iam.gserviceaccount.com \
    --parameters \
inputSubscription=projects/landing-lc01/subscriptions/sub1,\
outputTableSpec=dwh-lc01:bq_raw_dataset.person
```

## Manual pipeline Example: GCS to Bigquery

Once you deployed projects (step 1) and resources (step 2) you can use it to run your data pipeline. As first example below you can find set of manual steps for an end to end example.

In this example we will publish person message in the following format:

```bash
Lorenzo,Caggioni,1617898199
```

a Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

[TODO] An autorized view will be created in the datamart project to expose the table.
[TODO] Remove hardcoded 'lcaggio' variables and made ENV variable for it.
[TODO] Further automation is expected in future.

Create and download keys for Service accounts you created.

### Create BQ table

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

### Produce CSV data file, JSON schema file and UDF JS file

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

### Dataflow

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
