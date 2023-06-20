#!/usr/bin/env python

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
import time
import os

from airflow import models
from airflow.operators import dummy
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocCreateBatchOperator, DataprocDeleteBatchOperator, DataprocGetBatchOperator, DataprocListBatchesOperator

)
from airflow.utils.dates import days_ago

# --------------------------------------------------------------------------------
# Get variables
# --------------------------------------------------------------------------------
BQ_LOCATION = os.environ.get("BQ_LOCATION")
CURATED_BQ_DATASET = os.environ.get("CURATED_BQ_DATASET")
CURATED_GCS = os.environ.get("CURATED_GCS")
CURATED_PRJ = os.environ.get("CURATED_PRJ")
DP_KMS_KEY = os.environ.get("DP_KMS_KEY", "")
DP_REGION = os.environ.get("DP_REGION")
GCP_REGION = os.environ.get("GCP_REGION")
LAND_PRJ = os.environ.get("LAND_PRJ")
LAND_BQ_DATASET = os.environ.get("LAND_BQ_DATASET")
LAND_GCS = os.environ.get("LAND_GCS")
PHS_CLUSTER_NAME = os.environ.get("PHS_CLUSTER_NAME")
PROCESSING_GCS = os.environ.get("PROCESSING_GCS")
PROCESSING_PRJ = os.environ.get("PROCESSING_PRJ")
PROCESSING_SA = os.environ.get("PROCESSING_SA")
PROCESSING_SUBNET = os.environ.get("PROCESSING_SUBNET")
PROCESSING_VPC = os.environ.get("PROCESSING_VPC")

PYTHON_FILE_LOCATION = PROCESSING_GCS+"/pyspark_gcs2bq.py"
PHS_CLUSTER_PATH = "projects/"+PROCESSING_PRJ+"/regions/"+DP_REGION+"/clusters/"+PHS_CLUSTER_NAME
SPARK_BIGQUERY_JAR_FILE = "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.13-0.29.0.jar"
BATCH_ID = "batch-create-phs-"+str(int(time.time()))

default_args = {
    # Tell airflow to start one day ago, so that it runs as soon as you upload it
    "start_date": days_ago(1),
    "region": DP_REGION,
}
with models.DAG(
    "dataproc_batch_gcs2bq",  # The id you will see in the DAG airflow page
    default_args=default_args,  # The interval with which to schedule the DAG
    schedule_interval=None,  # Override to match your needs
) as dag:
    start = dummy.DummyOperator(
        task_id='start',
        trigger_rule='all_success'
    )

    end = dummy.DummyOperator(
        task_id='end',
        trigger_rule='all_success'
    )

    create_batch = DataprocCreateBatchOperator(
        task_id="batch_create",
        project_id=PROCESSING_PRJ,
        batch_id=BATCH_ID,
        batch={
            "environment_config": {
                "execution_config": {
                    "service_account": PROCESSING_SA,
                    "subnetwork_uri": PROCESSING_SUBNET
                },
                "peripherals_config": {
                    "spark_history_server_config":{
                        "dataproc_cluster": PHS_CLUSTER_PATH
                    }
                }
            },
            "pyspark_batch": {
                "args": [
                    LAND_GCS + "/customers.csv",
                    CURATED_PRJ + ":" + CURATED_BQ_DATASET + ".customers",
                    PROCESSING_GCS[5:]
                ],
                "main_python_file_uri": PYTHON_FILE_LOCATION,
                "jar_file_uris": [SPARK_BIGQUERY_JAR_FILE]
            }
        }
    )

    start >> create_batch >> end