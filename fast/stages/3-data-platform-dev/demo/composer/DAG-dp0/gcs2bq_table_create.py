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
BigQuery Table Creation DAG

This DAG creates BigQuery tables based on configuration stored in GCS.
It creates landing tables, curated tables, and an exposure view.
"""

import datetime
import logging
import os

from airflow import models
from airflow.models import Variable
from airflow.operators import empty
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCreateTableOperator,)
from airflow.providers.google.cloud.sensors.bigquery import (
    BigQueryTableExistenceSensor,)
from airflow.utils.task_group import TaskGroup

# Configuration
LANDING_TABLES = ["users", "orders", "order_items", "products"]
CURATED_TABLES = ["customer_purchases"]

# Environment variables (set from Composer variables.json)
DP_PROJECT = os.environ.get("DP_PROJECT")
LAND_BQ_DATASET = os.environ.get("LAND_BQ_DATASET")
CURATED_BQ_DATASET = os.environ.get("CURATED_BQ_DATASET")
EXPOSURE_BQ_DATASET = os.environ.get("EXPOSURE_BQ_DATASET")
LAND_GCS = os.environ.get("LAND_GCS")
DP_PROCESSING_SERVICE_ACCOUNT = os.environ.get("DP_PROCESSING_SERVICE_ACCOUNT")

# Validate required environment variables
required_vars = {
    "DP_PROJECT": DP_PROJECT,
    "LAND_BQ_DATASET": LAND_BQ_DATASET,
    "CURATED_BQ_DATASET": CURATED_BQ_DATASET,
    "EXPOSURE_BQ_DATASET": EXPOSURE_BQ_DATASET,
    "LAND_GCS": LAND_GCS,
    "DP_PROCESSING_SERVICE_ACCOUNT": DP_PROCESSING_SERVICE_ACCOUNT,
}

missing_vars = [var for var, value in required_vars.items() if not value]
if missing_vars:
  raise ValueError(f"Missing required environment variables: {missing_vars}")

logger = logging.getLogger(__name__)


def create_bq_table_task(table_name: str, dataset_name: str, schema_path: str,
                         task_prefix: str = "") -> BigQueryCreateTableOperator:
  """
    Factory function to create BigQuery table tasks.

    Args:
        table_name: Name of the table to create
        dataset_name: Name of the dataset
        schema_path: Path to schema files in GCS
        task_prefix: Prefix for task ID

    Returns:
        BigQueryCreateTableOperator instance
    """
  task_id = (f"{task_prefix}_{table_name}_create"
             if task_prefix else f"{table_name}_create")

  return BigQueryCreateTableOperator(
      task_id=task_id,
      project_id=DP_PROJECT,
      dataset_id=dataset_name,
      table_id=table_name,
      table_resource={},
      if_exists="log",
      gcs_schema_object=f"gs://{LAND_GCS}/{schema_path}/{table_name}.json",
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
    "sla": datetime.timedelta(hours=1),
}

with models.DAG(
    "gcs2bq_table_create",
    default_args=default_args,
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["bigquery", "table-creation", "data-platform"],
    doc_md=__doc__,
    dagrun_timeout=datetime.timedelta(hours=2),
) as dag:
  # Start and end markers
  start = empty.EmptyOperator(task_id="start", trigger_rule="all_success")
  end = empty.EmptyOperator(task_id="end", trigger_rule="all_done")

  # Create landing tables
  with TaskGroup("create_landing_tables",
                 tooltip="Create all landing layer tables") as landing_group:
    landing_tasks = []
    for table in LANDING_TABLES:
      task = create_bq_table_task(
          table_name=table,
          dataset_name=LAND_BQ_DATASET,
          schema_path="schemas/landing",
          task_prefix="land",
      )
      landing_tasks.append(task)

  # Create curated tables
  with TaskGroup("create_curated_tables",
                 tooltip="Create all curated layer tables") as curated_group:
    curated_tasks = []
    for table in CURATED_TABLES:
      task = create_bq_table_task(
          table_name=table,
          dataset_name=CURATED_BQ_DATASET,
          schema_path="schemas/curated",
          task_prefix="curated",
      )
      curated_tasks.append(task)

  # Validate all tables exist
  with TaskGroup(
      "validate_tables",
      tooltip="Validate all tables were created") as validation_group:
    # Create validation tasks for landing tables
    landing_validations = [
        create_table_validation_task(
            table_name=table,
            dataset_name=LAND_BQ_DATASET,
            task_prefix="validate_landing",
        ) for table in LANDING_TABLES
    ]

    # Create validation tasks for curated tables
    curated_validations = [
        create_table_validation_task(
            table_name=table,
            dataset_name=CURATED_BQ_DATASET,
            task_prefix="validate_curated",
        ) for table in CURATED_TABLES
    ]

  # Create exposure view
  exposure_view = BigQueryCreateTableOperator(
      task_id="exposure_view_create",
      project_id=DP_PROJECT,
      dataset_id=EXPOSURE_BQ_DATASET,
      table_id="customer_purchases",
      table_resource={
          "view": {
              "query":
                  f"SELECT * FROM `{DP_PROJECT}.{CURATED_BQ_DATASET}.customer_purchases`",
              "useLegacySql":
                  False,
          },
      },
      if_exists="log",
      impersonation_chain=[DP_PROCESSING_SERVICE_ACCOUNT],
  )

  # Validate exposure view exists
  validate_exposure_view = create_table_validation_task(
      table_name="customer_purchases",
      dataset_name=EXPOSURE_BQ_DATASET,
      task_prefix="validate_exposure",
  )

  # Define dependencies
  start >> [landing_group, curated_group]
  [landing_group, curated_group] >> validation_group
  validation_group >> exposure_view
  exposure_view >> validate_exposure_view >> end
