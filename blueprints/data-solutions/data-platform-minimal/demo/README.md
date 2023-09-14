# Data ingestion Demo

In this folder, you can find Airflow DAG examples to process data on the `minimal data platform` instantiated [here](../). Examples are focused on importing data from `landing` to `curated` resources.

Examples are not intended to be a production-ready code, but a bollerplate to verify and test the setup.

## Demo use case

The demo imports CSV customer data from the `landing` GCS bucket to the `curated` BigQuery dataset.

## Input files

Data are uploaded to the `landing` GCS bucket. File structure:

- [`customers.csv`](./data/customers.csv): Comma separate value with customer information in the following format: Customer ID, Name, Surname, Registration Timestamp

## Configuration files

Data relies on the following configuration files:

- [`customers_schema.json`](./data/customers_schema.json): customer BigQuery table schema definition.
- [`customers_udf.js`](./data/customers_udf.js): dataflow user defined function to transform CSV files into BigQuery schema
- [`customers.json`](./data/customers.json): customer CSV file schema definition

## Data processing pipelines

Different data pipelines are provided to highlight different ways import data.

Below you can find a description of each example:

- `bq_import.py`: Importing data using BigQuery import capability.
- `dataflow_import.py`: Importing data using Cloud Dataflow.
- `dataproc_import.py`: Importing data using Cloud Dataproc.

## Running the demo

To run demo examples, please follow the following steps:

1. Copy sample data to the `landing` Cloud Storage bucket impersonating the `landing` service account.
1. Copy sample data structure definition in the `processing` Cloud Storage bucket impersonating the `orchestration` service account.
1. Copy the Cloud Composer DAG to the Cloud Composer Storage bucket impersonating the `orchestration` service account.
1. Open the Cloud Composer Airflow UI and run the imported DAG.
1. Run the BigQuery query to see results.

Below you can find computed commands to perform steps.

```bash
terraform output -json | jq -r '@sh "export LND_SA=\(.service_accounts.value.landing)\nexport PRC_SA=\(.service_accounts.value.processing)\nexport CMP_SA=\(.service_accounts.value.composer)"' > env.sh

terraform output -json | jq -r '@sh "export LND_GCS=\(.gcs_buckets.value.landing)\nexport PRC_GCS=\(.gcs_buckets.value.processing)\nexport CUR_GCS=\(.gcs_buckets.value.curated)\nexport CMP_GCS=\(.composer.value.dag_bucket)"' >> env.sh

source ./env.sh

gsutil -i $LND_SA cp demo/data/*.csv gs://$LND_GCS
gsutil -i $CMP_SA cp demo/data/*.j* gs://$PRC_GCS
gsutil -i $CMP_SA cp demo/pyspark_* gs://$PRC_GCS
gsutil -i $CMP_SA cp demo/dag_*.py gs://$CMP_GCS/dags
```
