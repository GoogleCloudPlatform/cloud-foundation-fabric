# Copyright 2019 Google LLC
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

output "terraform_project" {
  description = "Project that holds the base Terraform resources."
  value       = module.project-tf.project_id
}

output "bootstrap_tf_gcs_bucket" {
  description = "GCS bucket used for the bootstrap Terraform state."
  value       = module.gcs-tf-bootstrap.name
}

output "environment_folders" {
  description = "Top-level environment folders."
  value       = zipmap(var.environments, module.folders-top-level.ids)
}

output "environment_tf_gcs_buckets" {
  description = "GCS buckets used for each environment Terraform state."
  value       = zipmap(var.environments, module.gcs-tf-environments.names)
}

output "environment_service_accounts" {
  description = "Service accounts used to run each environment Terraform modules."
  value       = zipmap(var.environments, module.service-accounts-tf-environments.emails)
}

output "audit_logs_bq_dataset" {
  description = "Bigquery dataset for the audit logs export."
  value       = module.bq-audit-export.resource_name
}

output "audit_logs_project" {
  description = "Project that holds the audit logs export resources."
  value       = module.project-audit.project_id
}

output "shared_resources_project" {
  description = "Project that holdes resources shared across environments."
  value       = module.project-shared-resources.project_id
}

# Add further outputs here for the additional modules that manage shared
# resources, like GCR, GCS buckets, KMS, etc.
