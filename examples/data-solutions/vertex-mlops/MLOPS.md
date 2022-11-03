# MLOps with Vertex AI


## Set up the required tables

For the Vertex MLOps end2end example we will use the public dataset `bigquery-public-data:ml_datasets.ulb_fraud_detection` that contains anonymized credit card transactions made over 2 days in September 2013 by European cardholders, with 492 frauds out of 284,807 transactions.

```
Andrea Dal Pozzolo, Olivier Caelen, Reid A. Johnson and Gianluca Bontempi. Calibrating Probability with Undersampling for Unbalanced Classification. In Symposium on Computational Intelligence and Data Mining (CIDM), IEEE, 2015
```

If the destinatio dataset is located in a different region from the source dataset (US) you will need to copy the data to the desired region. You can use the Data Transfer Service or an extracing/load procedure such as the following one:

```
#Set up env vars
PROJECT=<your Project ID>
SRC_TABLE=bigquery-public-data:ml_datasets.ulb_fraud_detection
BQ_DATASET_NAME=credit_cards_pro_eu
BQ_SOURCE_TABLE=creditcards
ML_TABLE=creditcards_ml
DST_TABLE=$BQ_DATASET_NAME.$BQ_SOURCE_TABLE
BUCKET=gs://$PROJECT-eu/data/credit_cards*

#Extract & Load
bq extract --project_id $PROJECT --destination_format PARQUET $SRC_TABLE  $BUCKET
bq load    --project_id $PROJECT --source_format=PARQUET --replace=true $DST_TABLE $BUCKET 
gsutil rm $BUCKET
```

As next steps, we will create the base table we will use for the ML process:
```

sql_script="CREATE OR REPLACE TABLE \`${PROJECT}.${BQ_DATASET_NAME}.${ML_TABLE}\` 
AS (
    SELECT 
      * EXCEPT(Class),
      CAST(Class AS FLOAT64) as Class,
      IF(ABS(MOD(FARM_FINGERPRINT(CAST(Time AS STRING)), 100)) <= 80, 'UNASSIGNED', 'TEST') AS ML_use
    FROM
      \`${PROJECT}.${BQ_DATASET_NAME}.${BQ_SOURCE_TABLE}\`
)
"

bq query --project_id $PROJECT --nouse_legacy_sql "$sql_script"
```


For the experimentation environment several alternatives are valid, from providing access to the created tables to create an authorized view. For this example, we will just create a new table that will be a subset of all the available data.


```
PROJECT_EXP=cxt1-credit-cards
BQ_DATASET_NAME_EXP=credit_cards_eu


sql_script="CREATE OR REPLACE TABLE \`${PROJECT_EXP}.${BQ_DATASET_NAME_EXP}.${ML_TABLE}\` 
AS (
    SELECT * 
    FROM \`${PROJECT}.${BQ_DATASET_NAME}.${ML_TABLE}\`
    LIMIT 140000
)
"

bq query --project_id $PROJECT --nouse_legacy_sql "$sql_script"
```

## Set up the Vertex managed Dataset
Run the following commands to setup the Vertex Dataset.

````

bq_uri="bq://${PROJECT}.${BQ_DATASET_NAME}.${ML_TABLE}"
${bq_uri}

echo "{
  \"display_name\": \"creditcards\",
  \"metadata_schema_uri\": \"gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml\",
  \"metadata\": {
    \"input_config\": {
      \"bigquery_source\" :{
        \"uri\": \"${bq_uri}\" 
      }
    }
  }
}" > request.json


REGION=europe-west4
ENDPOINT=$REGION-aiplatform.googleapis.com

curl -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @request.json \
"https://${ENDPOINT}/v1/projects/${PROJECT}/locations/${REGION}/datasets"



```