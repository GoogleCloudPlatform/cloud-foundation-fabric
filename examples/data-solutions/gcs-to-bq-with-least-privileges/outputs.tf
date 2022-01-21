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

output "bq_tables" {
  description = "Bigquery Tables."
  value       = module.bigquery-dataset.table_ids
}

output "buckets" {
  description = "GCS bucket Cloud KMS crypto keys."
  value = {
    data   = module.gcs-data.name
    df-tmp = module.gcs-df-tmp.name
  }
}

output "project_id" {
  description = "Project id."
  value       = module.project.project_id
}

output "service_accounts" {
  description = "Service account."
  value = {
    bq      = module.service-account-bq.email
    df      = module.service-account-df.email
    orch    = module.service-account-orch.email
    landing = module.service-account-landing.email
  }
}

output "command_01_gcs" {
  description = "gcloud command to copy data into the created bucket impersonating the service account."
  value       = "gsutil -i ${module.service-account-landing.email} cp data-demo/* ${module.gcs-data.url}"
}

output "command_02_dataflow" {
  description = "Command to run Dataflow template impersonating the service account."
  # FIXME Maybe use templatefile() for this?
  value = <<-EOT
    gcloud \
      --impersonate-service-account=${module.service-account-orch.email} \
      dataflow jobs run test_batch_01 \
      --gcs-location gs://dataflow-templates/latest/GCS_Text_to_BigQuery \
      --project ${module.project.project_id} \
      --region ${var.region} \
      --disable-public-ips \
      --subnetwork ${module.vpc.subnets["${var.region}/subnet"].self_link} \
      --staging-location ${module.gcs-df-tmp.url} \
      --service-account-email ${module.service-account-df.email} \
      ${var.cmek_encryption ? "--dataflow-kms-key=${module.kms[0].key_ids.key-df}" : ""} \
      --parameters \
    javascriptTextTransformFunctionName=transform,\
    JSONPath=${module.gcs-data.url}/person_schema.json,\
    javascriptTextTransformGcsPath=${module.gcs-data.url}/person_udf.js,\
    inputFilePattern=${module.gcs-data.url}/person.csv,\
    outputTable=${module.project.project_id}:${module.bigquery-dataset.dataset_id}.${module.bigquery-dataset.tables["person"].table_id},\
    bigQueryLoadingTemporaryDirectory=${module.gcs-df-tmp.url} 
  EOT
}

output "command_03_bq" {
  description = "BigQuery command to query imported data."
  value       = <<-EOT
    bq query --project_id=${module.project.project_id} --use_legacy_sql=false \
      'SELECT * FROM `${module.project.project_id}.${module.bigquery-dataset.dataset_id}.${module.bigquery-dataset.tables["person"].table_id}` LIMIT 1000'"
  EOT
}
