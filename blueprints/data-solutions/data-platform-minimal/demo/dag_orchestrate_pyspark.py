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

import time

from airflow import models
from airflow.models.variable import Variable
from airflow.operators import empty
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocCreateBatchOperator
)
from airflow.utils.dates import days_ago

# --------------------------------------------------------------------------------
# Get variables
# --------------------------------------------------------------------------------
BQ_LOCATION = Variable.get("BQ_LOCATION")
CURATED_BQ_DATASET = Variable.get("CURATED_BQ_DATASET")
CURATED_GCS = Variable.get("CURATED_GCS")
CURATED_PRJ = Variable.get("CURATED_PRJ")
DP_KMS_KEY = Variable.get("DP_KMS_KEY", "")
DP_REGION = Variable.get("DP_REGION")
LAND_PRJ = Variable.get("LAND_PRJ")
LAND_BQ_DATASET = Variable.get("LAND_BQ_DATASET")
LAND_GCS = Variable.get("LAND_GCS")
PHS_CLUSTER_NAME = Variable.get("PHS_CLUSTER_NAME")
PROCESSING_GCS = Variable.get("PROCESSING_GCS")
PROCESSING_PRJ = Variable.get("PROCESSING_PRJ")
PROCESSING_SA = Variable.get("PROCESSING_SA")
PROCESSING_SUBNET = Variable.get("PROCESSING_SUBNET")
PROCESSING_VPC = Variable.get("PROCESSING_VPC")

PYTHON_FILE_LOCATION = PROCESSING_GCS + "/pyspark_sort.py"
PHS_CLUSTER_PATH = f"projects/{PROCESSING_PRJ}/regions/{DP_REGION}/clusters/{PHS_CLUSTER_NAME}"
BATCH_ID = "batch-create-phs-" + str(int(time.time()))

default_args = {
    # Tell airflow to start one day ago, so that it runs as soon as you upload it
    "start_date": days_ago(1),
    "region": DP_REGION,
}
with models.DAG(
    "dataproc_batch_operators",  # The id you will see in the DAG airflow page
    default_args=default_args,  # The interval with which to schedule the DAG
    schedule_interval=None,  # Override to match your needs
) as dag:
    start = empty.EmptyOperator(
        task_id='start',
        trigger_rule='all_success'
    )

    end = empty.EmptyOperator(
        task_id='end',
        trigger_rule='all_success'
    )    

    create_batch = DataprocCreateBatchOperator(
        task_id="batch_create",
        project_id=PROCESSING_PRJ,
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
                "args": ["pippo"],
                "main_python_file_uri": PYTHON_FILE_LOCATION,
            }
        },
        batch_id=BATCH_ID,
    )

    start >> create_batch >> end