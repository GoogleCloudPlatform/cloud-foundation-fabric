# Copyright 2025 Google LLC
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
"""
BigQuery ELT Pipeline DAG

This DAG implements a comprehensive customer purchases ELT pipeline that:
1. Loads data from GCS to BigQuery landing tables (users, orders, order_items, products)
2. Performs a 4-table join to create a comprehensive customer_purchases table
3. Creates an exposure view for analytics consumption

Dependencies: Requires gcs2bq_table_create DAG to complete first
"""

import datetime
import json
import logging
import os
from typing import Dict

import jsonschema
from airflow import models
from airflow.decorators import task
from airflow.models import Variable
from airflow.operators import empty
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCheckOperator,
    BigQueryInsertJobOperator,
)
from airflow.providers.google.cloud.sensors.bigquery import (
    BigQueryTableExistenceSensor,)
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import (
    GCSToBigQueryOperator,)
from airflow.utils.task_group import TaskGroup
from google.api_core import retry
from google.cloud import storage

# Configuration
GCS_CONFIG_PATH = "variables.json"
LANDING_TABLES = ["users", "orders", "order_items", "products"]

# Configuration schema for validation
CONFIG_SCHEMA = {
    "type":
        "object",
    "properties": {
        "DP_PROJECT": {
            "type": "string"
        },
        "LAND_BQ_DATASET": {
            "type": "string"
        },
        "CURATED_BQ_DATASET": {
            "type": "string"
        },
        "LAND_GCS": {
            "type": "string"
        },
        "DP_PROCESSING_SERVICE_ACCOUNT": {
            "type": "string"
        },
        "LOCATION": {
            "type": "string"
        },
    },
    "required": [
        "DP_PROJECT",
        "LAND_BQ_DATASET",
        "CURATED_BQ_DATASET",
        "LAND_GCS",
        "DP_PROCESSING_SERVICE_ACCOUNT",
        "LOCATION",
    ],
}

logger = logging.getLogger(__name__)


@task(task_id="load_config", retries=3)
def load_config_from_gcs() -> Dict:
  """
    Reads and validates JSON config file from GCS /data folder.

    Returns:
        Dict: Configuration dictionary
    """
  try:
    # Read directly from mounted data folder (recommended for Composer)
    data_path = "/home/airflow/gcs/data"
    config_path = os.path.join(data_path, GCS_CONFIG_PATH)

    if os.path.exists(config_path):
      with open(config_path, "r") as f:
        config = json.load(f)
    else:
      # Use GCS client as fallback
      bucket_name = Variable.get("composer_gcs_bucket", default_var=None)
      if not bucket_name:
        raise ValueError("Could not determine GCS bucket name")

      @retry.Retry(timeout=30, deadline=60)
      def download_config():
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(f"data/{GCS_CONFIG_PATH}")

        if not blob.exists():
          raise FileNotFoundError(
              f"Config file not found at gs://{bucket_name}/data/{GCS_CONFIG_PATH}"
          )

        return blob.download_as_string()

      config_str = download_config()
      config = json.loads(config_str)

    # Validate configuration against schema
    jsonschema.validate(config, CONFIG_SCHEMA)
    logger.info(
        f"Successfully loaded and validated configuration for project: {config['DP_PROJECT']}"
    )

    return config

  except Exception as e:
    logger.error(f"Failed to load configuration: {str(e)}")
    raise


def create_gcs_to_bq_task(project_id: str,
                          table_name: str) -> GCSToBigQueryOperator:
  """
    Factory function to create GCS to BigQuery load tasks.

    Args:
        table_name: Name of the table to load

    Returns:
        GCSToBigQueryOperator instance
    """
  return GCSToBigQueryOperator(
      task_id=f"{table_name}_load",
      bucket="{{ ti.xcom_pull(task_ids='load_config')['LAND_GCS'] }}",
      source_objects=f"data/{table_name}/{table_name}_*.csv",
      destination_project_dataset_table=(
          "{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}"
          ".{{ ti.xcom_pull(task_ids='load_config')['LAND_BQ_DATASET'] }}"
          f".{table_name}"),
      source_format="CSV",
      create_disposition="CREATE_IF_NEEDED",
      write_disposition="WRITE_TRUNCATE",
      schema_object=f"schemas/landing/{table_name}.json",
      schema_object_bucket=
      "{{ ti.xcom_pull(task_ids='load_config')['LAND_GCS'] }}",
      autodetect=False,
      max_bad_records=1,
      project_id=project_id,
      impersonation_chain=[
          "{{ ti.xcom_pull(task_ids='load_config')['DP_PROCESSING_SERVICE_ACCOUNT'] }}"
      ],
  )


def create_table_validation_task(
    table_name: str, dataset_key: str = "LAND_BQ_DATASET",
    task_prefix: str = "validate") -> BigQueryTableExistenceSensor:
  """
    Factory function to create table validation tasks using sensor.

    Args:
        table_name: Name of the table to validate
        dataset_key: Config key for the dataset
        task_prefix: Prefix for task ID

    Returns:
        BigQueryTableExistenceSensor instance
    """
  return BigQueryTableExistenceSensor(
      task_id=f"{task_prefix}_{table_name}_exists",
      project_id="{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}",
      dataset_id=
      f"{{{{ ti.xcom_pull(task_ids='load_config')['{dataset_key}'] }}}}",
      table_id=table_name,
      poke_interval=30,  # Check every 30 seconds
      timeout=600,  # Timeout after 10 minutes
      mode="reschedule",  # Release worker slot between checks
      impersonation_chain=[
          "{{ ti.xcom_pull(task_ids='load_config')['DP_PROCESSING_SERVICE_ACCOUNT'] }}"
      ],
  )


# DAG Definition
yesterday = datetime.datetime.now() - datetime.timedelta(days=1)

default_args = {
    "owner": "data-platform-team",
    "start_date": yesterday,
    "depends_on_past": False,
    "email": Variable.get("alert_email_list", default_var="").split(","),
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5),
    "sla": datetime.timedelta(hours=2),
}

with models.DAG(
    "gcs2bq_elt",
    default_args=default_args,
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["bigquery", "elt", "data-platform", "customer-purchases"],
    doc_md=__doc__,
    dagrun_timeout=datetime.timedelta(hours=3),
) as dag:
  # Start and end markers
  start = empty.EmptyOperator(task_id="start", trigger_rule="all_success")
  end = empty.EmptyOperator(task_id="end", trigger_rule="all_done")

  # Get project ID from an environment variable set in the Composer environment.
  # This is used for operator fields that are not Jinja-templated.
  dp_project_id_for_gcs_op = os.environ.get("DP_PROJECT")
  if not dp_project_id_for_gcs_op:
    raise ValueError("DP_PROJECT environment variable not set.")

  # Load configuration from GCS. This is used by all templated fields.
  config_task = load_config_from_gcs()

  # Validate that all required tables exist before starting data load
  with TaskGroup(
      "validate_prerequisites",
      tooltip="Validate all landing tables exist before data load",
  ) as prerequisites_group:
    prerequisite_validations = [
        create_table_validation_task(
            table_name=table,
            dataset_key="LAND_BQ_DATASET",
            task_prefix="validate_landing",
        ) for table in LANDING_TABLES
    ]
    # Validate that the curated customer_purchases table exists from a previous run
    validate_customer_purchases_prereq = create_table_validation_task(
        table_name="customer_purchases",
        dataset_key="CURATED_BQ_DATASET",
        task_prefix="validate_curated",
    )

  # Load data from GCS to BigQuery landing tables
  with TaskGroup("load_landing_data",
                 tooltip="Load all data files to landing tables") as load_group:
    load_tasks = [
        create_gcs_to_bq_task(project_id=dp_project_id_for_gcs_op,
                              table_name=table) for table in LANDING_TABLES
    ]

  # Create comprehensive customer purchases join
  customer_purchases_join = BigQueryInsertJobOperator(
      task_id="create_customer_purchases",
      project_id="{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}",
      configuration={
          "jobType": "QUERY",
          "query": {
              "query":
                  """
                SELECT
                  -- User information
                  u.id as user_id,
                  u.first_name,
                  u.last_name,
                  u.email,
                  u.age,
                  u.gender,
                  u.state,
                  u.street_address,
                  u.postal_code,
                  u.city,
                  u.country,
                  u.latitude,
                  u.longitude,
                  u.traffic_source,
                  u.created_at as user_created_at,
                  u.user_geom,

                  -- Order information
                  o.order_id,
                  o.status as order_status,
                  o.created_at as order_created_at,
                  o.returned_at as order_returned_at,
                  o.shipped_at as order_shipped_at,
                  o.delivered_at as order_delivered_at,
                  o.num_of_item,

                  -- Order item information
                  oi.id as order_item_id,
                  oi.product_id,
                  oi.inventory_item_id,
                  oi.status as order_item_status,
                  oi.sale_price,
                  oi.created_at as order_item_created_at,
                  oi.shipped_at as order_item_shipped_at,
                  oi.delivered_at as order_item_delivered_at,
                  oi.returned_at as order_item_returned_at,

                  -- Product information
                  p.cost,
                  p.category,
                  p.name,
                  p.brand,
                  p.retail_price,
                  p.department,
                  p.sku,
                  p.distribution_center_id

                FROM `{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}.{{ ti.xcom_pull(task_ids='load_config')['LAND_BQ_DATASET'] }}.users` u
                JOIN `{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}.{{ ti.xcom_pull(task_ids='load_config')['LAND_BQ_DATASET'] }}.orders` o
                  ON u.id = o.user_id
                JOIN `{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}.{{ ti.xcom_pull(task_ids='load_config')['LAND_BQ_DATASET'] }}.order_items` oi
                  ON o.order_id = oi.order_id
                JOIN `{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}.{{ ti.xcom_pull(task_ids='load_config')['LAND_BQ_DATASET'] }}.products` p
                  ON oi.product_id = p.id
              """,
              "destinationTable": {
                  "projectId":
                      "{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}",
                  "datasetId":
                      "{{ ti.xcom_pull(task_ids='load_config')['CURATED_BQ_DATASET'] }}",
                  "tableId":
                      "customer_purchases",
              },
              "writeDisposition":
                  "WRITE_TRUNCATE",
              "useLegacySql":
                  False,
          },
      },
      impersonation_chain=[
          "{{ ti.xcom_pull(task_ids='load_config')['DP_PROCESSING_SERVICE_ACCOUNT'] }}"
      ],
  )

  # Validate that the customer_purchases table has data after the join
  validate_customer_purchases_data = BigQueryCheckOperator(
      task_id="validate_customer_purchases_data",
      sql=
      ("SELECT COUNT(*) > 0 FROM `{{ ti.xcom_pull(task_ids='load_config')['DP_PROJECT'] }}."
       "{{ ti.xcom_pull(task_ids='load_config')['CURATED_BQ_DATASET'] }}.customer_purchases`"
      ),
      use_legacy_sql=False,
      impersonation_chain=[
          "{{ ti.xcom_pull(task_ids='load_config')['DP_PROCESSING_SERVICE_ACCOUNT'] }}"
      ],
  )

  # Define dependencies
  start >> config_task
  config_task >> prerequisites_group
  prerequisites_group >> load_group
  load_group >> customer_purchases_join
  customer_purchases_join >> validate_customer_purchases_data >> end
