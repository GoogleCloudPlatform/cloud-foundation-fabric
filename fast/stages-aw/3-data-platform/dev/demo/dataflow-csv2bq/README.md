## Pipeline summary
This demo serves as a simple example of building and launching a Flex Template Dataflow pipeline. The code mainly focuses on reading a CSV file as input along with a JSON schema file as side input. The pipeline Parses both inputs and writes the data to the relevant BigQuery table while applying the schema passed from input.

![Dataflow pipeline overview](../../images/df_demo_pipeline.png "Dataflow pipeline overview")


## Local development run

For local development, the pipeline can be launched from the local machine for testing purposes using different runners depending on the scope of the test.

### Using the Beam DirectRunner
The below example uses the Beam DirectRunner. The use case for this runner is mainly for quick local tests on the development environment with low volume of data.

```
CSV_FILE=gs://[TEST-BUCKET]/customers.csv
JSON_SCHEMA=gs://[TEST-BUCKET]/customers_schema.json
OUTPUT_TABLE=[TEST-PROJ].[TEST-DATASET].customers
PIPELINE_STAGIN_PATH="gs://[TEST-STAGING-BUCKET]"

python src/csv2bq.py \
--runner="DirectRunner" \
--csv_file=$CSV_FILE \
--json_schema=$JSON_SCHEMA \
--output_table=$OUTPUT_TABLE \
--temp_location=$PIPELINE_STAGIN_PATH/tmp
```

*Note:* All paths mentioned can be local paths or on GCS. For cloud resources referenced (GCS and BigQuery), make sure that the user launching the command is authenticated to GCP via `gcloud auth application-default login` and has the required access privileges to those resources.

### Using the DataflowRunner with a local CLI launch

The below example triggers the pipeline on Dataflow from your local development environment. The use case for this is for running local tests on larger volumes of test data and verifying that the pipeline runs well on Dataflow, before compiling it into a template.

```
PROJECT_ID=[TEST-PROJECT]
REGION=[REGION]
SUBNET=[SUBNET-NAME]
DEV_SERVICE_ACCOUNT=[DEV-SA]

PIPELINE_STAGIN_PATH="gs://[TEST-STAGING-BUCKET]"
CSV_FILE=gs://[TEST-BUCKET]/customers.csv
JSON_SCHEMA=gs://[TEST-BUCKET]/customers_schema.json
OUTPUT_TABLE=[TEST-PROJ].[TEST-DATASET].customers

python src/csv2bq.py \
--runner="Dataflow" \
--project=$PROJECT_ID \
--region=$REGION \
--csv_file=$CSV_FILE \
--json_schema=$JSON_SCHEMA \
--output_table=$OUTPUT_TABLE \
--temp_location=$PIPELINE_STAGIN_PATH/tmp
--staging_location=$PIPELINE_STAGIN_PATH/stage \
--subnetwork="regions/$REGION/subnetworks/$SUBNET" \
--impersonate_service_account=$DEV_SERVICE_ACCOUNT \
--no_use_public_ips
```

In terms of resource access privilege, you can choose to impersonate another service account, which could be defined for development resource access. The authenticated user launching this pipeline will need to have the role `roles/iam.serviceAccountTokenCreator`. If you choose to launch the pipeline without service account impersonation, it will use the default compute service account assigned of the target project.

## Dataflow Flex Template run

For production, and as outline in the Data Platform demo, we build and launch the pipeline as a Flex Template, making it available for other cloud services(such as Apache Airflow) and users to trigger launch instances of it on demand.

### Build launch

Below is an example for triggering the Dataflow flex template build pipeline defined in `cloudbuild.yaml`. The Terraform output provides an example as well filled with the parameters values based on the generated resources in the data platform.

```
GCP_PROJECT="[ORCHESTRATION-PROJECT]"
TEMPLATE_IMAGE="[REGION].pkg.dev/[ORCHESTRATION-PROJECT]/[REPOSITORY]/csv2bq:latest"
TEMPLATE_PATH="gs://[DATAFLOW-TEMPLATE-BUCKEt]/csv2bq.json"
STAGIN_PATH="gs://[ORCHESTRATION-STAGING-BUCKET]/build"
LOG_PATH="gs://[ORCHESTRATION-LOGS-BUCKET]/logs"
REGION="[REGION]"
BUILD_SERVICE_ACCOUNT=orc-sa-df-build@[SERVICE_PROJECT_ID].iam.gserviceaccount.com

gcloud builds submit \
           --config=cloudbuild.yaml \
           --project=$GCP_PROJECT \
           --region=$REGION \
           --gcs-log-dir=$LOG_PATH \
           --gcs-source-staging-dir=$STAGIN_PATH \
           --substitutions=_TEMPLATE_IMAGE=$TEMPLATE_IMAGE,_TEMPLATE_PATH=$TEMPLATE_PATH,_DOCKER_DIR="." \
           --impersonate-service-account=$BUILD_SERVICE_ACCOUNT
```

**Note:** For the scope of the demo, the launch of this build is manual, but in production, this build would be launched via a configured cloud build trigger when new changes are merged into the code branch of the Dataflow template.

### Dataflow Flex Template run 

After the build step succeeds. You can launch dataflow pipeline from CLI (outline in this example) or the API via Airflow's operator. For the use case of the data platform, the Dataflow pipeline would be launched via the orchestration service account, which is what the Airflow DAG is also using in the scope of this demo.

**Note:** In the data platform demo, the launch of this Dataflow pipeline is handled by the airflow operator (DataflowStartFlexTemplateOperator).

```
#!/bin/bash

PROJECT_ID=[LOAD-PROJECT]
REGION=[REGION]
ORCH_SERVICE_ACCOUNT=orchestrator@[SERVICE_PROJECT_ID].iam.gserviceaccount.com
SUBNET=[SUBNET-NAME]

PIPELINE_STAGIN_PATH="gs://[LOAD-STAGING-BUCKET]/build"
CSV_FILE=gs://[DROP-ZONE-BUCKET]/customers.csv
JSON_SCHEMA=gs://[ORCHESTRATION-BUCKET]/customers_schema.json
OUTPUT_TABLE=[DESTINATION-PROJ].[DESTINATION-DATASET].customers
TEMPLATE_PATH=gs://[ORCHESTRATION-DF-GCS]/csv2bq.json


gcloud dataflow flex-template run "csv2bq-`date +%Y%m%d-%H%M%S`" \
    --template-file-gcs-location $TEMPLATE_PATH \
    --parameters temp_location="$PIPELINE_STAGIN_PATH/tmp" \
    --parameters staging_location="$PIPELINE_STAGIN_PATH/stage" \
    --parameters csv_file=$CSV_FILE \
    --parameters json_schema=$JSON_SCHEMA\
    --parameters output_table=$OUTPUT_TABLE \
    --region $REGION \
    --project $PROJECT_ID \
    --subnetwork="regions/$REGION/subnetworks/$SUBNET" \
    --service-account-email=$ORCH_SERVICE_ACCOUNT
```
