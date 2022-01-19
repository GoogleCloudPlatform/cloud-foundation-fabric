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
# --------------------------------------------------------------------------------

LND_GCS = os.environ.get("LND_GCS")
LOD_GCS_STAGING = os.environ.get("LOD_GCS_STAGING")
DTL_L0_BQ_DATASET = os.environ.get("DTL_L0_BQ_DATASET")
DTL_L0_PRJ = os.environ.get("DTL_L0_PRJ")
DTL_L1_BQ_DATASET = os.environ.get("DTL_L1_BQ_DATASET")
DTL_L1_PRJ = os.environ.get("DTL_L1_PRJ")
LOD_PRJ = os.environ.get("LOD_PRJ")
DF_ZONE = os.environ.get("GCP_REGION") + "-b"
DF_REGION = BQ_REGION = os.environ.get("GCP_REGION")
NET_VPC = os.environ.get("NET_VPC")
NET_SUBNET = "https://www.googleapis.com/compute/v1/projects/lc-04-lod/regions/europe-west1/subnetworks/subnet" #"https://www.googleapis.com/compute/v1/" + os.environ.get("NET_SUBNET")
LOD_SA_DF = os.environ.get("LOD_SA_DF")
TRF_SA_DF = os.environ.get("TRF_SA_DF")
TRF_SA_BQ = os.environ.get("TRF_SA_BQ")
TRF_PRJ = os.environ.get("TRF_PRJ")

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
    'subnetwork': NET_SUBNET,
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
      "JSONPath": LND_GCS + "/customers_schema.json",
      "javascriptTextTransformGcsPath": LND_GCS + "/customers_udf.js",
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
      "JSONPath": LND_GCS + "/purchases_schema.json",
      "javascriptTextTransformGcsPath": LND_GCS + "/purchases_udf.js",
      "inputFilePattern": LND_GCS + "/purchases.csv",
      "outputTable": DTL_L0_PRJ + ":"+DTL_L0_BQ_DATASET+".purchases",
      "bigQueryLoadingTemporaryDirectory": LOD_GCS_STAGING + "/tmp/bq/",
    },
  )

  join_customer_purchase = BigQueryInsertJobOperator(
    task_id='bq_join_customer_purchase',
    gcp_conn_id='bigquery_default',
    project_id=TRF_PRJ,
    location=BQ_REGION,
    configuration={
      'jobType':'QUERY',
      'writeDisposition':'WRITE_TRUNCATE',
      'query':{
        'query':"""SELECT  
                  c.id as customer_id,
                  p.id as purchase_id,
                  c.name as name,
                  c.surname as surname,
                  p.item as item,
                  p.price as price,
                  p.timestamp as timestamp
                FROM `lc-04-dtl-0.lc_04_dtl_0_bq_0.customers` c
                JOIN `lc-04-dtl-0.lc_04_dtl_0_bq_0.purchases` p ON c.id = p.customer_id 
              """,
        'destinationTable':{
          'projectId': DTL_L1_PRJ,
          'datasetId': DTL_L1_BQ_DATASET,
          'tableId': 'customer_purchase'          
        },
        "useLegacySql": False
      }
    },
    impersonation_chain=[TRF_SA_BQ]    
  )
  
  start >> [customers_import, purchases_import] >> join_customer_purchase >> end
