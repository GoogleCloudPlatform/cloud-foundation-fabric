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
import logging
import os

from airflow import models
from airflow.decorators import task
from airflow.models import Variable
from airflow.operators import empty
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator,)
from airflow.providers.google.cloud.sensors.bigquery import (
    BigQueryTableExistenceSensor,)
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import (
    GCSToBigQueryOperator,)
from airflow.utils.task_group import TaskGroup

# Configuration
LANDING_TABLES = ["users", "orders", "order_items", "products"]

# Environment variables (set from composer/variables.json)
DP_PROJECT = Variable.get("DP_PROJECT")
LAND_BQ_DATASET = Variable.get("LAND_BQ_DATASET")
CURATED_BQ_DATASET = Variable.get("CURATED_BQ_DATASET")
LAND_GCS = Variable.get("LAND_GCS")
DP_PROCESSING_SERVICE_ACCOUNT = Variable.get("DP_PROCESSING_SERVICE_ACCOUNT")
LOCATION = Variable.get("LOCATION")

# Validate required environment variables
required_vars = {
    "DP_PROJECT": DP_PROJECT,
    "LAND_BQ_DATASET": LAND_BQ_DATASET,
    "CURATED_BQ_DATASET": CURATED_BQ_DATASET,
    "LAND_GCS": LAND_GCS,
    "DP_PROCESSING_SERVICE_ACCOUNT": DP_PROCESSING_SERVICE_ACCOUNT,
    "LOCATION": LOCATION,
}

missing_vars = [var for var, value in required_vars.items() if not value]
if missing_vars:
  raise ValueError(f"Missing required environment variables: {missing_vars}")

logger = logging.getLogger(__name__)


def create_gcs_to_bq_task(table_name: str) -> GCSToBigQueryOperator:
  """
    Factory function to create GCS to BigQuery load tasks.

    Args:
        table_name: Name of the table to load

    Returns:
        GCSToBigQueryOperator instance
    """
  return GCSToBigQueryOperator(
      task_id=f"{table_name}_load",
      bucket=LAND_GCS,
      source_objects=f"data/{table_name}/{table_name}_*.csv",
      destination_project_dataset_table=
      f"{DP_PROJECT}.{LAND_BQ_DATASET}.{table_name}",
      source_format="CSV",
      create_disposition="CREATE_IF_NEEDED",
      write_disposition="WRITE_TRUNCATE",
      schema_object=f"schemas/landing/{table_name}.json",
      schema_object_bucket=LAND_GCS,
      autodetect=False,
      max_bad_records=1,
      project_id=DP_PROJECT,
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
  )


def create_table_validation_task(
    table_name: str, dataset_name: str,
    task_prefix: str = "validate") -> BigQueryTableExistenceSensor:
  """
    Factory function to create table validation tasks using sensor.

    Args:
        table_name: Name of the table to validate
        dataset_name: Name of the dataset
        task_prefix: Prefix for task ID

    Returns:
        BigQueryTableExistenceSensor instance
    """
  return BigQueryTableExistenceSensor(
      task_id=f"{task_prefix}_{table_name}_exists",
      project_id=DP_PROJECT,
      dataset_id=dataset_name,
      table_id=table_name,
      poke_interval=30,  # Check every 30 seconds
      timeout=600,  # Timeout after 10 minutes
      mode="reschedule",  # Release worker slot between checks
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
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

  # Validate that all required tables exist before starting data load
  with TaskGroup(
      "validate_prerequisites",
      tooltip="Validate all landing tables exist before data load",
  ) as prerequisites_group:
    prerequisite_validations = [
        create_table_validation_task(
            table_name=table,
            dataset_name=LAND_BQ_DATASET,
            task_prefix="validate_landing",
        ) for table in LANDING_TABLES
    ]
    # Validate that the curated customer_purchases table exists from a previous run
    validate_customer_purchases_prereq = create_table_validation_task(
        table_name="customer_purchases",
        dataset_name=CURATED_BQ_DATASET,
        task_prefix="validate_curated",
    )

  # Load data from GCS to BigQuery landing tables
  with TaskGroup("load_landing_data",
                 tooltip="Load all data files to landing tables") as load_group:
    load_tasks = [
        create_gcs_to_bq_task(table_name=table) for table in LANDING_TABLES
    ]

  # Create comprehensive customer purchases join
  customer_purchases_join = BigQueryInsertJobOperator(
      task_id="create_customer_purchases",
      project_id=DP_PROJECT,
      configuration={
          "jobType": "QUERY",
          "query": {
              "query":
                  f"""
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

                FROM `{DP_PROJECT}.{LAND_BQ_DATASET}.users` u
                JOIN `{DP_PROJECT}.{LAND_BQ_DATASET}.orders` o
                  ON u.id = o.user_id
                JOIN `{DP_PROJECT}.{LAND_BQ_DATASET}.order_items` oi
                  ON o.order_id = oi.order_id
                JOIN `{DP_PROJECT}.{LAND_BQ_DATASET}.products` p
                  ON oi.product_id = p.id
              """,
              "destinationTable": {
                  "projectId": DP_PROJECT,
                  "datasetId": CURATED_BQ_DATASET,
                  "tableId": "customer_purchases",
              },
              "writeDisposition":
                  "WRITE_TRUNCATE",
              "useLegacySql":
                  False,
          },
      },
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
  )

  @task(task_id="validate_customer_purchases_data")
  def validate_customer_purchases_data_python():
    """
        Checks if the customer_purchases table has data using BigQueryHook
        for robust cross-project execution.
        """
    project_id = DP_PROJECT
    dataset_id = CURATED_BQ_DATASET
    table_id = "customer_purchases"
    impersonation_account = DP_PROCESSING_SERVICE_ACCOUNT

    logging.info(
        f"Executing data validation check on table: {project_id}.{dataset_id}.{table_id}"
    )

    # The hook will use the impersonation chain for all interactions
    hook = BigQueryHook(
        gcp_conn_id="google_cloud_default",  # Assumes default connection
        impersonation_chain=[impersonation_account],
        location=LOCATION,
    )

    sql = f"SELECT COUNT(*) FROM `{project_id}.{dataset_id}.{table_id}`"

    # Use insert_job for cross-project execution with explicit project_id
    job_config = {"query": {"query": sql, "useLegacySql": False}}

    job = hook.insert_job(configuration=job_config, project_id=project_id)

    # Extract results from the completed job
    results = job.result()
    records = [list(row) for row in results]

    if not records or not records[0] or records[0][0] == 0:
      raise ValueError(
          f"Data quality check failed: Table {project_id}.{dataset_id}.{table_id} is empty or has no rows."
      )
    else:
      row_count = records[0][0]
      logging.info(
          f"Data quality check passed: Table {project_id}.{dataset_id}.{table_id} contains {row_count} rows."
      )

  validate_customer_purchases_data = validate_customer_purchases_data_python()

  # Define dependencies
  start >> prerequisites_group
  prerequisites_group >> load_group
  load_group >> customer_purchases_join
  customer_purchases_join >> validate_customer_purchases_data >> end
