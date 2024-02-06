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

# tfdoc:file:description Output variables.

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    curated = module.cur-bq-0.dataset_id
    landing = module.land-bq-0.dataset_id
  }
}

output "composer" {
  description = "Composer variables."
  value = {
    air_flow_uri = try(google_composer_environment.processing-cmp-0[0].config.0.airflow_uri, null)
    dag_bucket   = try(regex("^gs://([^/]*)/dags$", google_composer_environment.processing-cmp-0[0].config[0].dag_gcs_prefix)[0], null)
  }
}

output "dataproc-history-server" {
  description = "List of bucket names which have been assigned to the cluster."
  value       = one(module.processing-dp-historyserver)
}

output "gcs_buckets" {
  description = "GCS buckets."
  value = {
    curated    = module.cur-cs-0.name
    landing    = module.land-cs-0.name
    processing = module.processing-cs-0.name
  }
}

output "kms_keys" {
  description = "Cloud MKS keys."
  value       = var.service_encryption_keys
}

output "network" {
  description = "VPC network."
  value = {
    processing_subnet = local.processing_subnet
    processing_vpc    = local.processing_vpc
  }
}

output "projects" {
  description = "GCP Projects information."
  value = {
    project_number = {
      common     = module.common-project.number
      curated    = module.cur-project.number
      landing    = module.land-project.number
      processing = module.processing-project.number
    }
    project_id = {
      common     = module.common-project.project_id
      curated    = module.cur-project.project_id
      landing    = module.land-project.project_id
      processing = module.processing-project.project_id
    }
  }
}

output "service_accounts" {
  description = "Service account created."
  value = {
    composer   = module.processing-sa-cmp-0.email
    curated    = module.cur-sa-0.email,
    landing    = module.land-sa-0.email,
    processing = module.processing-sa-0.email,
  }
}
