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

output "environment_tf_gcs_buckets" {
  description = "GCS buckets used for each environment Terraform state."
  value       = module.gcs-tf-environments.names
}

output "environment_service_account_keys" {
  description = "Service account keys used to run each environment Terraform modules."
  sensitive   = true
  value       = module.service-accounts-tf-environments.keys
}

output "environment_service_accounts" {
  description = "Service accounts used to run each environment Terraform modules."
  value       = module.service-accounts-tf-environments.emails
}

output "shared_folder_id" {
  description = "Shared folder ID."
  value       = module.shared-folder.id
}
output "business_unit_1_folder_id" {
  description = "Business unit 1 top-level folder ID."
  value       = module.business-unit-1-folders.business_unit_folder_id
}

output "business_unit_1_environment_folders_ids" {
  description = "Business unit 1 environment folders."
  value       = module.business-unit-1-folders.environment_folders_ids
}

output "business_unit_2_folder_id" {
  description = "Business unit 2 top-level folder ID."
  value       = module.business-unit-2-folders.business_unit_folder_id
}

output "business_unit_2_environment_folders_ids" {
  description = "Business unit 2 environment folders."
  value       = module.business-unit-2-folders.environment_folders_ids
}

output "business_unit_3_folder_id" {
  description = "Business unit 3 top-level folder ID."
  value       = module.business-unit-3-folders.business_unit_folder_id
}

output "business_unit_3_environment_folders_ids" {
  description = "Business unit 3 environment folders."
  value       = module.business-unit-3-folders.environment_folders_ids
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
  description = "Project that holdes resources shared across business units."
  value       = module.project-shared-resources.project_id
}

# Add further outputs here for the additional modules that manage shared
# resources, like GCR, GCS buckets, KMS, etc.