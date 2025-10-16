/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"
}

resource "google_bigquery_connection" "connection" {
  project       = var.project_id
  location      = var.location
  connection_id = var.connection_id
  friendly_name = var.friendly_name
  description   = var.description
  kms_key_name  = var.encryption_key

  dynamic "cloud_sql" {
    for_each = var.connection_config.cloud_sql == null ? [] : [var.connection_config.cloud_sql]
    content {
      instance_id = cloud_sql.value.instance_id
      database    = cloud_sql.value.database
      type        = cloud_sql.value.type
      credential {
        username = cloud_sql.value.credential.username
        password = cloud_sql.value.credential.password
      }
    }
  }

  dynamic "aws" {
    for_each = var.connection_config.aws == null ? [] : [var.connection_config.aws]
    content {
      access_role {
        iam_role_id = aws.value.access_role.iam_role_id
        identity    = aws.value.access_role.identity
      }
    }
  }

  dynamic "azure" {
    for_each = var.connection_config.azure == null ? [] : [var.connection_config.azure]
    content {
      application                     = azure.value.application
      client_id                       = azure.value.client_id
      object_id                       = azure.value.object_id
      customer_tenant_id              = azure.value.customer_tenant_id
      federated_application_client_id = azure.value.federated_application_client_id
      redirect_uri                    = azure.value.redirect_uri
      identity                        = azure.value.identity
    }
  }

  dynamic "cloud_spanner" {
    for_each = var.connection_config.cloud_spanner == null ? [] : [var.connection_config.cloud_spanner]
    content {
      database        = cloud_spanner.value.database
      use_parallelism = cloud_spanner.value.use_parallelism
      use_data_boost  = cloud_spanner.value.use_data_boost
      max_parallelism = cloud_spanner.value.max_parallelism
      database_role   = cloud_spanner.value.database_role
    }
  }

  dynamic "cloud_resource" {
    for_each = var.connection_config.cloud_resource == null ? [] : [var.connection_config.cloud_resource]
    content {}
  }

  dynamic "spark" {
    for_each = var.connection_config.spark == null ? [] : [var.connection_config.spark]
    content {
      metastore_service_config {
        metastore_service = spark.value.metastore_service_config.metastore_service
      }
      spark_history_server_config {
        dataproc_cluster = spark.value.spark_history_server_config.dataproc_cluster
      }
    }
  }
}