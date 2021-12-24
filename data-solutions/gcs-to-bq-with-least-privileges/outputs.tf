# Copyright 2021 Google LLC
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
  description = "GCS Bucket Cloud KMS crypto keys."
  value = {
    for name, bucket in module.gcs-01 :
    bucket.name => bucket.url
  }
}

output "projects" {
  description = "Project ids."
  value = {
    service-project = module.project-service.project_id
  }
}

output "serviceaccount" {
  description = "Service Account."
  value = {
    bq   = module.service-account-bq.email
    df   = module.service-account-df.email
    orch = module.service-account-orch.email
  }
}

output "command-01-gcs" {
  description = "gcloud command to copy data into the created bucket impersonating the service account."
  value       = "gsutil -i ${module.service-account-landing.email} cp data-demo/* ${module.gcs-01["data-landing"].url}"
}

output "command-02-dataflow" {
  description = "gcloud command to run dataflow template impersonating the service account."
  value       = <<EOT
  gcloud --impersonate-service-account=${module.service-account-orch.email} dataflow jobs run test_batch_01 \
    --gcs-location gs://dataflow-templates/latest/GCS_Text_to_BigQuery \
    --project ${module.project-service.project_id} \
    --region ${var.region} \
    --disable-public-ips \
    --subnetwork ${module.vpc.subnets[format("%s/%s", var.region, "subnet")].self_link} \
    --staging-location ${module.gcs-01["df-tmplocation"].url} \
    --service-account-email ${module.service-account-df.email} \
    --parameters \
javascriptTextTransformFunctionName=transform,\
JSONPath=${module.gcs-01["data-landing"].url}/person_schema.json,\
javascriptTextTransformGcsPath=${module.gcs-01["data-landing"].url}/person_udf.js,\
inputFilePattern=${module.gcs-01["data-landing"].url}/person.csv,\
outputTable=${module.project-service.project_id}:${module.bigquery-dataset.dataset_id}.${module.bigquery-dataset.tables["person"].table_id},\
bigQueryLoadingTemporaryDirectory=${module.gcs-01["df-tmplocation"].url} 
  EOT
}

output "command-03-bq" {
  description = "bq command to query imported data."
  value       = "bq query --use_legacy_sql=false 'SELECT * FROM `${module.project-service.project_id}.${module.bigquery-dataset.dataset_id}.${module.bigquery-dataset.tables["person"].table_id}` LIMIT 1000'"
}
