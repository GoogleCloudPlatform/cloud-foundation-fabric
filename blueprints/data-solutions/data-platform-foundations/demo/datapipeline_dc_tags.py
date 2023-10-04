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

import datetime

from airflow import models
from airflow.models.variable import Variable
from airflow.providers.google.cloud.operators.dataflow import DataflowTemplatedJobStartOperator
from airflow.operators import empty
from airflow.providers.google.cloud.operators.bigquery import  BigQueryInsertJobOperator, BigQueryUpsertTableOperator, BigQueryUpdateTableSchemaOperator
from airflow.utils.task_group import TaskGroup

# --------------------------------------------------------------------------------
# Set variables - Needed for the DEMO
# --------------------------------------------------------------------------------
BQ_LOCATION = Variable.get("BQ_LOCATION")
DATA_CAT_TAGS = Variable.get("DATA_CAT_TAGS", deserialize_json=True)
DWH_LAND_PRJ = Variable.get("DWH_LAND_PRJ")
DWH_LAND_BQ_DATASET = Variable.get("DWH_LAND_BQ_DATASET")
DWH_LAND_GCS = Variable.get("DWH_LAND_GCS")
DWH_CURATED_PRJ = Variable.get("DWH_CURATED_PRJ")
DWH_CURATED_BQ_DATASET = Variable.get("DWH_CURATED_BQ_DATASET")
DWH_CURATED_GCS = Variable.get("DWH_CURATED_GCS")
DWH_CONFIDENTIAL_PRJ = Variable.get("DWH_CONFIDENTIAL_PRJ")
DWH_CONFIDENTIAL_BQ_DATASET = Variable.get("DWH_CONFIDENTIAL_BQ_DATASET")
DWH_CONFIDENTIAL_GCS = Variable.get("DWH_CONFIDENTIAL_GCS")
GCP_REGION = Variable.get("GCP_REGION")
DRP_PRJ = Variable.get("DRP_PRJ")
DRP_BQ = Variable.get("DRP_BQ")
DRP_GCS = Variable.get("DRP_GCS")
DRP_PS = Variable.get("DRP_PS")
LOD_PRJ = Variable.get("LOD_PRJ")
LOD_GCS_STAGING = Variable.get("LOD_GCS_STAGING")
LOD_NET_VPC = Variable.get("LOD_NET_VPC")
LOD_NET_SUBNET = Variable.get("LOD_NET_SUBNET")
LOD_SA_DF = Variable.get("LOD_SA_DF")
ORC_PRJ = Variable.get("ORC_PRJ")
ORC_GCS = Variable.get("ORC_GCS")
TRF_PRJ = Variable.get("TRF_PRJ")
TRF_GCS_STAGING = Variable.get("TRF_GCS_STAGING")
TRF_NET_VPC = Variable.get("TRF_NET_VPC")
TRF_NET_SUBNET = Variable.get("TRF_NET_SUBNET")
TRF_SA_DF = Variable.get("TRF_SA_DF")
TRF_SA_BQ = Variable.get("TRF_SA_BQ")
DF_KMS_KEY = Variable.get("DF_KMS_KEY", "")
DF_REGION = Variable.get("GCP_REGION")
DF_ZONE = Variable.get("GCP_REGION") + "-b"

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
    'location': DF_REGION,
    'zone': DF_ZONE,
    'stagingLocation': LOD_GCS_STAGING,
    'tempLocation': LOD_GCS_STAGING + "/tmp",
    'serviceAccountEmail': LOD_SA_DF,
    'subnetwork': LOD_NET_SUBNET,
    'ipConfiguration': "WORKER_IP_PRIVATE",
    'kmsKeyName' : DF_KMS_KEY
  },
}

# --------------------------------------------------------------------------------
# Main DAG
# --------------------------------------------------------------------------------

with models.DAG(
    'data_pipeline_dc_tags_dag',
    default_args=default_args,
    schedule_interval=None) as dag:
  start = empty.EmptyOperator(
    task_id='start',
    trigger_rule='all_success'
  )

  end = empty.EmptyOperator(
    task_id='end',
    trigger_rule='all_success'
  )

  # Bigquery Tables created here for demo porpuse. 
  # Consider a dedicated pipeline or tool for a real life scenario.
  with TaskGroup('upsert_table') as upsert_table:  
    upsert_table_customers = BigQueryUpsertTableOperator(
      task_id="upsert_table_customers",
      project_id=DWH_LAND_PRJ,
      dataset_id=DWH_LAND_BQ_DATASET,
      impersonation_chain=[LOD_SA_DF],
      table_resource={
        "tableReference": {"tableId": "customers"},
      },
    )  

    upsert_table_purchases = BigQueryUpsertTableOperator(
      task_id="upsert_table_purchases",
      project_id=DWH_LAND_PRJ,
      dataset_id=DWH_LAND_BQ_DATASET,
      impersonation_chain=[LOD_SA_DF],      
      table_resource={
        "tableReference": {"tableId": "purchases"}
      },
    )   

    upsert_table_customer_purchase_curated = BigQueryUpsertTableOperator(
      task_id="upsert_table_customer_purchase_curated",
      project_id=DWH_CURATED_PRJ,
      dataset_id=DWH_CURATED_BQ_DATASET,
      impersonation_chain=[TRF_SA_BQ],
      table_resource={
        "tableReference": {"tableId": "customer_purchase"}
      },
    )   

    upsert_table_customer_purchase_confidential = BigQueryUpsertTableOperator(
      task_id="upsert_table_customer_purchase_confidential",
      project_id=DWH_CONFIDENTIAL_PRJ,
      dataset_id=DWH_CONFIDENTIAL_BQ_DATASET,
      impersonation_chain=[TRF_SA_BQ],
      table_resource={
        "tableReference": {"tableId": "customer_purchase"}
      },
    )       

  # Bigquery Tables schema defined here for demo porpuse. 
  # Consider a dedicated pipeline or tool for a real life scenario.
  with TaskGroup('update_schema_table') as update_schema_table:  
    update_table_schema_customers = BigQueryUpdateTableSchemaOperator(
      task_id="update_table_schema_customers",
      project_id=DWH_LAND_PRJ,
      dataset_id=DWH_LAND_BQ_DATASET,
      table_id="customers",
      impersonation_chain=[LOD_SA_DF],
      include_policy_tags=True,
      schema_fields_updates=[
        { "mode": "REQUIRED", "name": "id", "type": "INTEGER", "description": "ID" },
        { "mode": "REQUIRED", "name": "name", "type": "STRING", "description": "Name", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]}},
        { "mode": "REQUIRED", "name": "surname", "type": "STRING", "description": "Surname", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]} },
        { "mode": "REQUIRED", "name": "timestamp", "type": "TIMESTAMP", "description": "Timestamp" }
      ]
    )  

    update_table_schema_customers = BigQueryUpdateTableSchemaOperator(
      task_id="update_table_schema_purchases",
      project_id=DWH_LAND_PRJ,
      dataset_id=DWH_LAND_BQ_DATASET,
      table_id="purchases",
      impersonation_chain=[LOD_SA_DF],
      include_policy_tags=True,
      schema_fields_updates=[ 
        {  "mode": "REQUIRED",  "name": "id",  "type": "INTEGER",  "description": "ID" }, 
        {  "mode": "REQUIRED",  "name": "customer_id",  "type": "INTEGER",  "description": "ID" }, 
        {  "mode": "REQUIRED",  "name": "item",  "type": "STRING",  "description": "Item Name" }, 
        {  "mode": "REQUIRED",  "name": "price",  "type": "FLOAT",  "description": "Item Price" }, 
        {  "mode": "REQUIRED",  "name": "timestamp",  "type": "TIMESTAMP",  "description": "Timestamp" }
      ]
    )    

    update_table_schema_customer_purchase_curated = BigQueryUpdateTableSchemaOperator(
      task_id="update_table_schema_customer_purchase_curated",
      project_id=DWH_CURATED_PRJ,
      dataset_id=DWH_CURATED_BQ_DATASET,
      table_id="customer_purchase",
      impersonation_chain=[TRF_SA_BQ],
      include_policy_tags=True,
      schema_fields_updates=[
        { "mode": "REQUIRED", "name": "customer_id", "type": "INTEGER", "description": "ID" },
        { "mode": "REQUIRED", "name": "purchase_id", "type": "INTEGER", "description": "ID" },
        { "mode": "REQUIRED", "name": "name", "type": "STRING", "description": "Name", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]}},
        { "mode": "REQUIRED", "name": "surname", "type": "STRING", "description": "Surname", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]} },
        { "mode": "REQUIRED", "name": "item", "type": "STRING", "description": "Item Name" },
        { "mode": "REQUIRED", "name": "price", "type": "FLOAT", "description": "Item Price" },
        { "mode": "REQUIRED", "name": "timestamp", "type": "TIMESTAMP", "description": "Timestamp" }
      ]
    )

    update_table_schema_customer_purchase_confidential = BigQueryUpdateTableSchemaOperator(
      task_id="update_table_schema_customer_purchase_confidential",
      project_id=DWH_CONFIDENTIAL_PRJ,
      dataset_id=DWH_CONFIDENTIAL_BQ_DATASET,
      table_id="customer_purchase",
      impersonation_chain=[TRF_SA_BQ],
      include_policy_tags=True,
      schema_fields_updates=[
        { "mode": "REQUIRED", "name": "customer_id", "type": "INTEGER", "description": "ID" },
        { "mode": "REQUIRED", "name": "purchase_id", "type": "INTEGER", "description": "ID" },
        { "mode": "REQUIRED", "name": "name", "type": "STRING", "description": "Name", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]}},
        { "mode": "REQUIRED", "name": "surname", "type": "STRING", "description": "Surname", "policyTags": { "names": [DATA_CAT_TAGS.get('2_Private', None)]} },
        { "mode": "REQUIRED", "name": "item", "type": "STRING", "description": "Item Name" },
        { "mode": "REQUIRED", "name": "price", "type": "FLOAT", "description": "Item Price" },
        { "mode": "REQUIRED", "name": "timestamp", "type": "TIMESTAMP", "description": "Timestamp" }
      ]
    )

  customers_import = DataflowTemplatedJobStartOperator(
    task_id="dataflow_customers_import",
    template="gs://dataflow-templates/latest/GCS_Text_to_BigQuery",
    project_id=LOD_PRJ,
    location=DF_REGION,
    parameters={
      "javascriptTextTransformFunctionName": "transform",
      "JSONPath": ORC_GCS + "/customers_schema.json",
      "javascriptTextTransformGcsPath": ORC_GCS + "/customers_udf.js",
      "inputFilePattern": DRP_GCS + "/customers.csv",
      "outputTable": DWH_LAND_PRJ + ":" + DWH_LAND_BQ_DATASET + ".customers",
      "bigQueryLoadingTemporaryDirectory": LOD_GCS_STAGING + "/tmp/bq/",
    },
  )

  purchases_import = DataflowTemplatedJobStartOperator(
    task_id="dataflow_purchases_import",
    template="gs://dataflow-templates/latest/GCS_Text_to_BigQuery",
    project_id=LOD_PRJ,
    location=DF_REGION,
    parameters={
      "javascriptTextTransformFunctionName": "transform",
      "JSONPath": ORC_GCS + "/purchases_schema.json",
      "javascriptTextTransformGcsPath": ORC_GCS + "/purchases_udf.js",
      "inputFilePattern": DRP_GCS + "/purchases.csv",
      "outputTable": DWH_LAND_PRJ + ":" + DWH_LAND_BQ_DATASET + ".purchases",
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
                FROM `{dwh_0_prj}.{dwh_0_dataset}.customers` c
                JOIN `{dwh_0_prj}.{dwh_0_dataset}.purchases` p ON c.id = p.customer_id
              """.format(dwh_0_prj=DWH_LAND_PRJ, dwh_0_dataset=DWH_LAND_BQ_DATASET, ),
        'destinationTable':{
          'projectId': DWH_CURATED_PRJ,
          'datasetId': DWH_CURATED_BQ_DATASET,
          'tableId': 'customer_purchase'
        },
        'writeDisposition':'WRITE_APPEND',
        "useLegacySql": False
      }
    },
    impersonation_chain=[TRF_SA_BQ]
  )

  confidential_customer_purchase = BigQueryInsertJobOperator(
    task_id='bq_confidential_customer_purchase',
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
                FROM `{dwh_cur_prj}.{dwh_cur_dataset}.customer_purchase`
              """.format(dwh_cur_prj=DWH_CURATED_PRJ, dwh_cur_dataset=DWH_CURATED_BQ_DATASET, ),
        'destinationTable':{
          'projectId': DWH_CONFIDENTIAL_PRJ,
          'datasetId': DWH_CONFIDENTIAL_BQ_DATASET,
          'tableId': 'customer_purchase'
        },
        'writeDisposition':'WRITE_APPEND',
        "useLegacySql": False
      }
    },
    impersonation_chain=[TRF_SA_BQ]
  )
  start >> upsert_table >> update_schema_table >> [customers_import, purchases_import] >> join_customer_purchase >> confidential_customer_purchase >> end  
