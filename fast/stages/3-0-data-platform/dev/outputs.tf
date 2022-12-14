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

# tfdoc:file:description Output variables.

locals {
  tfvars = {
    bigquery_dataset = module.data-platform.bigquery-datasets
    gcs_buckets      = module.data-platform.gcs-buckets
    projects         = module.data-platform.projects
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/03-data-platform-dev.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/03-data-platform-dev.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

# outputs

output "bigquery_datasets" {
  description = "BigQuery datasets."
  value       = module.data-platform.bigquery-datasets
}

output "demo_commands" {
  description = "Demo commands."
  value       = module.data-platform.demo_commands
}

output "gcs_buckets" {
  description = "GCS buckets."
  value       = module.data-platform.gcs-buckets
}

output "kms_keys" {
  description = "Cloud MKS keys."
  value       = module.data-platform.kms_keys
}

output "projects" {
  description = "GCP Projects informations."
  value       = module.data-platform.projects
}

output "vpc_network" {
  description = "VPC network."
  value       = module.data-platform.vpc_network
}

output "vpc_subnet" {
  description = "VPC subnetworks."
  value       = module.data-platform.vpc_subnet
}
