# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# --------------------------------------------------------------------------------
# Load The Dependencies
# --------------------------------------------------------------------------------

import datetime

from airflow import models
from airflow.models.variable import Variable
from airflow.operators import empty
from airflow.providers.google.cloud.operators.bigquery import \
  BigQueryInsertJobOperator, BigQueryCreateTableOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import \
  GCSToBigQueryOperator

# --------------------------------------------------------------------------------
# Set variables - Needed for the DEMO
# --------------------------------------------------------------------------------
EXPOSURE_BQ_DATASET = Variable.get("EXPOSURE_BQ_DATASET")
LOCATION = Variable.get("LOCATION")
CURATED_BQ_DATASET = Variable.get("CURATED_BQ_DATASET")
LAND_BQ_DATASET = Variable.get("LAND_BQ_DATASET")
LAND_GCS = Variable.get("LAND_GCS")
DP_PROJECT = Variable.get("DP_PROJECT")
DP_PROCESSING_SERVICE_ACCOUNT = Variable.get("DP_PROCESSING_SERVICE_ACCOUNT")

# --------------------------------------------------------------------------------
# Set default arguments
# --------------------------------------------------------------------------------

yesterday = datetime.datetime.now() - datetime.timedelta(days=1)

default_args = {
    'owner': 'airflow',
    'start_date': yesterday,
    'depends_on_past': False,
    'email': [''],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': datetime.timedelta(minutes=5)
}

# --------------------------------------------------------------------------------
# Main DAG
# --------------------------------------------------------------------------------

with models.DAG('data_pipeline_dag', default_args=default_args,
                schedule_interval=None) as dag:
  start = empty.EmptyOperator(task_id='start', trigger_rule='all_success')

  end = empty.EmptyOperator(task_id='end', trigger_rule='all_success')

  customers_load = GCSToBigQueryOperator(
      task_id='customers_load', bucket=LAND_GCS,
      source_objects=['customers.csv'
                     ], destination_project_dataset_table='{}:{}.{}'.format(
                         DP_PROJECT, LAND_BQ_DATASET, 'customers'),
      create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND',
      schema_object="schema/customers.json", schema_object_bucket=LAND_GCS,
      schema_update_options=['ALLOW_FIELD_RELAXATION',
                             'ALLOW_FIELD_ADDITION'], project_id=DP_PROJECT,
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT])

  purchases_load = GCSToBigQueryOperator(
      task_id='purchases_load', bucket=LAND_GCS,
      source_objects=['purchases.csv'
                     ], destination_project_dataset_table='{}:{}.{}'.format(
                         DP_PROJECT, LAND_BQ_DATASET, 'purchases'),
      create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND',
      schema_object="schema/purchases.json", schema_object_bucket=LAND_GCS,
      schema_update_options=['ALLOW_FIELD_RELAXATION',
                             'ALLOW_FIELD_ADDITION'], project_id=DP_PROJECT,
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT])

  join_customer_purchase = BigQueryInsertJobOperator(
      task_id='bq_join_customer_purchase', gcp_conn_id='bigquery_default',
      project_id=DP_PROJECT, location=LOCATION, configuration={
          'jobType': 'QUERY',
          'query': {
              'query':
                  """SELECT
                  c.id as customer_id,
                  p.id as purchase_id,
                  p.item as item,
                  p.price as price,
                  p.timestamp as timestamp
                FROM `{dp_prj}.{dp_lnd_dataset}.customers` c
                JOIN `{dp_prj}.{dp_lnd_dataset}.purchases` p ON c.id = p.customer_id
              """.format(
                      dp_prj=DP_PROJECT,
                      dp_lnd_dataset=LAND_BQ_DATASET,
                  ),
              'destinationTable': {
                  'projectId': DP_PROJECT,
                  'datasetId': CURATED_BQ_DATASET,
                  'tableId': 'customer_purchase'
              },
              'writeDisposition':
                  'WRITE_TRUNCATE',
              "useLegacySql":
                  False
          }
      }, impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT])

start >> [customers_load, purchases_load] >> join_customer_purchase >> end
