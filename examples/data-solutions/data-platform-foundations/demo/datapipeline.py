# Copyright 2022 Google LLC
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

import csv
import datetime
import io
import logging
import os

from airflow import models
from airflow.contrib.operators.dataflow_operator import DataflowTemplateOperator
from airflow.operators import dummy
from airflow.providers.google.cloud.operators.bigquery import  BigQueryInsertJobOperator

# --------------------------------------------------------------------------------
# Set variables
# ------------------------------------------------------------
BQ_LOCATION = os.environ.get("BQ_LOCATION")
DTL_L0_PRJ = os.environ.get("DTL_L0_PRJ")
DTL_L0_BQ_DATASET = os.environ.get("DTL_L0_BQ_DATASET")
DTL_L0_GCS = os.environ.get("DTL_L0_GCS")
DTL_L1_PRJ = os.environ.get("DTL_L1_PRJ")
DTL_L1_BQ_DATASET = os.environ.get("DTL_L1_BQ_DATASET")
DTL_L1_GCS = os.environ.get("DTL_L1_GCS")
DTL_L2_PRJ = os.environ.get("DTL_L2_PRJ")
DTL_L2_BQ_DATASET = os.environ.get("DTL_L2_BQ_DATASET")
DTL_L2_GCS = os.environ.get("DTL_L2_GCS")
DTL_PLG_PRJ = os.environ.get("DTL_PLG_PRJ")
DTL_PLG_BQ_DATASET = os.environ.get("DTL_PLG_BQ_DATASET")
DTL_PLG_GCS = os.environ.get("DTL_PLG_GCS")
GCP_REGION = os.environ.get("GCP_REGION")
LND_PRJ = os.environ.get("LND_PRJ")
LND_BQ = os.environ.get("LND_BQ")
LND_GCS = os.environ.get("LND_GCS")
LND_PS = os.environ.get("LND_PS")
LOD_PRJ = os.environ.get("LOD_PRJ")
LOD_GCS_STAGING = os.environ.get("LOD_GCS_STAGING")
LOD_NET_VPC = os.environ.get("LOD_NET_VPC")
LOD_NET_SUBNET = os.environ.get("LOD_NET_SUBNET")
LOD_SA_DF = os.environ.get("LOD_SA_DF")
ORC_PRJ = os.environ.get("ORC_PRJ")
ORC_GCS = os.environ.get("ORC_GCS")
TRF_PRJ = os.environ.get("TRF_PRJ")
TRF_GCS_STAGING = os.environ.get("TRF_GCS_STAGING")
TRF_NET_VPC = os.environ.get("TRF_NET_VPC")
TRF_NET_SUBNET = os.environ.get("TRF_NET_SUBNET")
TRF_SA_DF = os.environ.get("TRF_SA_DF")
TRF_SA_BQ = os.environ.get("TRF_SA_BQ")
DF_ZONE = os.environ.get("GCP_REGION") + "-b"
DF_REGION = os.environ.get("GCP_REGION")

# --------------------------------------------------------------------------------
# Set default arguments
# --------------------------------------------------------------------------------

# If you are running Airflow in more than one time zone
# see https://airflow.apache.org/docs/apache-airflow/stable/timezone.html
# for best practices
yesterday = datetime.datetime.now() - datetime.timedelta(days=1)

default_args = {
  'owner': 'airflow',
  'start_date': yesterday,
  'depends_on_past': False,
  'email': [''],
  'email_on_failure': False,
  'email_on_retry': False,
  'retries': 1,
  'retry_delay': datetime.timedelta(minutes=5),
  'dataflow_default_options': {
    'project': LOD_PRJ,
    'location': DF_REGION,
    'zone': DF_ZONE,
    'stagingLocation': LOD_GCS_STAGING,
    'tempLocation': LOD_GCS_STAGING + "/tmp",
    'serviceAccountEmail': LOD_SA_DF,
    'subnetwork': LOD_NET_SUBNET,
    'ipConfiguration': "WORKER_IP_PRIVATE"
  },
}

# --------------------------------------------------------------------------------
# Main DAG
# --------------------------------------------------------------------------------

with models.DAG(
    'data_pipeline_dag',
    default_args=default_args,
    schedule_interval=None) as dag:
  start = dummy.DummyOperator(
    task_id='start',
    trigger_rule='all_success'
  )

  end = dummy.DummyOperator(
    task_id='end',
    trigger_rule='all_success'
  )

  customers_import = DataflowTemplateOperator(
    task_id="dataflow_customer_import",
    template="gs://dataflow-templates/latest/GCS_Text_to_BigQuery",
    parameters={
      "javascriptTextTransformFunctionName": "transform",
      "JSONPath": ORC_GCS + "/customers_schema.json",
      "javascriptTextTransformGcsPath": ORC_GCS + "/customers_udf.js",
      "inputFilePattern": LND_GCS + "/customers.csv",
      "outputTable": DTL_L0_PRJ + ":"+DTL_L0_BQ_DATASET+".customers",
      "bigQueryLoadingTemporaryDirectory": LOD_GCS_STAGING + "/tmp/bq/",
    },
  )

  purchases_import = DataflowTemplateOperator(
    task_id="dataflow_purchases_import",
    template="gs://dataflow-templates/latest/GCS_Text_to_BigQuery",
    parameters={
      "javascriptTextTransformFunctionName": "transform",
      "JSONPath": ORC_GCS + "/purchases_schema.json",
      "javascriptTextTransformGcsPath": ORC_GCS + "/purchases_udf.js",
      "inputFilePattern": LND_GCS + "/purchases.csv",
      "outputTable": DTL_L0_PRJ + ":"+DTL_L0_BQ_DATASET+".purchases",
      "bigQueryLoadingTemporaryDirectory": LOD_GCS_STAGING + "/tmp/bq/",
    },
  )

  join_customer_purchase = BigQueryInsertJobOperator(
    task_id='bq_join_customer_purchase',
    gcp_conn_id='bigquery_default',
    project_id=TRF_PRJ,
    location=BQ_LOCATION,
    configuration={
      'jobType':'QUERY',
      'query':{
        'query':"""SELECT
                  c.id as customer_id,
                  p.id as purchase_id,
                  c.name as name,
                  c.surname as surname,
                  p.item as item,
                  p.price as price,
                  p.timestamp as timestamp
                FROM `{dtl_0_prj}.{dtl_0_dataset}.customers` c
                JOIN `{dtl_0_prj}.{dtl_0_dataset}.purchases` p ON c.id = p.customer_id
              """.format(dtl_0_prj=DTL_L0_PRJ, dtl_0_dataset=DTL_L0_BQ_DATASET, ),
        'destinationTable':{
          'projectId': DTL_L1_PRJ,
          'datasetId': DTL_L1_BQ_DATASET,
          'tableId': 'customer_purchase'
        },
        'writeDisposition':'WRITE_TRUNCATE',
        "useLegacySql": False
      }
    },
    impersonation_chain=[TRF_SA_BQ]
  )

  l2_customer_purchase = BigQueryInsertJobOperator(
    task_id='bq_l2_customer_purchase',
    gcp_conn_id='bigquery_default',
    project_id=TRF_PRJ,
    location=BQ_LOCATION,
    configuration={
      'jobType':'QUERY',
      'query':{
        'query':"""SELECT
                     customer_id,
                     purchase_id,
                     name,
                     surname,
                     item,
                     price,
                     timestamp
                FROM `{dtl_1_prj}.{dtl_1_dataset}.customer_purchase`
              """.format(dtl_1_prj=DTL_L1_PRJ, dtl_1_dataset=DTL_L1_BQ_DATASET, ),
        'destinationTable':{
          'projectId': DTL_L2_PRJ,
          'datasetId': DTL_L2_BQ_DATASET,
          'tableId': 'customer_purchase'
        },
        'writeDisposition':'WRITE_TRUNCATE',
        "useLegacySql": False
      }
    },
    impersonation_chain=[TRF_SA_BQ]
  )

  start >> [customers_import, purchases_import] >> join_customer_purchase >> l2_customer_purchase >> end
