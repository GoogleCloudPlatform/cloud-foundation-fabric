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

with models.DAG('table_creation', default_args=default_args,
                schedule_interval=None) as dag:
  start = empty.EmptyOperator(task_id='start', trigger_rule='all_success')

  end = empty.EmptyOperator(task_id='end', trigger_rule='all_success')

  landing_tables = ["users", "orders", "order_items", "products"]
  curated_tables = ["customer_purchases"]

  create_land_tables = []
  for table in landing_tables:
    task = BigQueryCreateTableOperator(
        task_id='{}_create'.format(table),
        project_id=DP_PROJECT,
        dataset_id=LAND_BQ_DATASET,
        table_id=table,
        table_resource={},
        if_exists="skip",
        gcs_schema_object="gs://{}/schemas/landing/{}.json".format(
            LAND_GCS, table),
        impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
    )
    create_land_tables.append(task)

  create_curated_tables = []
  for table in curated_tables:
    task = BigQueryCreateTableOperator(
        task_id='{}_create'.format(table),
        project_id=DP_PROJECT,
        dataset_id=CURATED_BQ_DATASET,
        table_id=table,
        table_resource={},
        if_exists="skip",
        gcs_schema_object="gs://{}/schemas/curated/{}.json".format(
            LAND_GCS, table),
        impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
    )
    create_curated_tables.append(task)

  exposure_view = BigQueryCreateTableOperator(
      task_id="exposure_view", project_id=DP_PROJECT,
      dataset_id=EXPOSURE_BQ_DATASET, table_id="customer_purchases",
      table_resource={
          "view": {
              "query":
                  """
                  SELECT * FROM `{dp_prj}.{dp_curated_dataset}.customer_purchases`
              """.format(
                      dp_prj=DP_PROJECT,
                      dp_curated_dataset=CURATED_BQ_DATASET,
                  ),
              "useLegacySql":
                  False,
          },
      }, impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT])

  all_creations = create_land_tables + create_curated_tables
  start >> all_creations >> exposure_view >> end
