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

output "business_unit_1_top_level_folder_id" {
  description = "Business unit 1 top-level folder."
  value       = module.business-unit-1-folders-tree.top_level_folder_id
}

output "business_unit_1_envs_folders_ids" {
  description = "Business unit 1 environment folders."
  value       = module.business-unit-1-folders-tree.second_level_folders_ids
}

output "business_unit_1_envs_tf_gcs_buckets" {
  description = "GCS buckets used for each environment Terraform state for business unit 1."
  value       = module.business-unit-1-folders-tree.second_level_folders_tf_gcs_bucket_names
}

output "business_unit_1_envs_service_account_keys" {
  description = "Service account keys used to run each environment Terraform modules for business unit 1."
  sensitive   = true
  value       = module.business-unit-1-folders-tree.second_level_folders_service_account_keys
}

output "business_unit_1_envs_service_accounts" {
  description = "Service accounts used to run each environment Terraform modules for business unit 1."
  value       = module.business-unit-1-folders-tree.second_level_folders_service_account_emails
}

output "business_unit_2_top_level_folder_id" {
  description = "Business unit 2 top-level folder."
  value       = module.business-unit-2-folders-tree.top_level_folder_id
}

output "business_unit_2_envs_folders_ids" {
  description = "Business unit 2 environment folders."
  value       = module.business-unit-2-folders-tree.second_level_folders_ids
}

output "business_unit_2_envs_tf_gcs_buckets" {
  description = "GCS buckets used for each environment Terraform state for business unit 2."
  value       = module.business-unit-2-folders-tree.second_level_folders_tf_gcs_bucket_names
}

output "business_unit_2_envs_service_account_keys" {
  description = "Service account keys used to run each environment Terraform modules for business unit 2."
  sensitive   = true
  value       = module.business-unit-2-folders-tree.second_level_folders_service_account_keys
}

output "business_unit_2_envs_service_accounts" {
  description = "Service accounts used to run each environment Terraform modules for business unit 2."
  value       = module.business-unit-2-folders-tree.second_level_folders_service_account_emails
}

output "business_unit_3_top_level_folder_id" {
  description = "Business unit 3 top-level folder."
  value       = module.business-unit-3-folders-tree.top_level_folder_id
}

output "business_unit_3_envs_folders_ids" {
  description = "Business unit 3 environment folders."
  value       = module.business-unit-3-folders-tree.second_level_folders_ids
}

output "business_unit_3_envs_tf_gcs_buckets" {
  description = "GCS buckets used for each environment Terraform state for business unit 3."
  value       = module.business-unit-3-folders-tree.second_level_folders_tf_gcs_bucket_names
}

output "business_unit_3_envs_service_account_keys" {
  description = "Service account keys used to run each environment Terraform modules for business unit 3."
  sensitive   = true
  value       = module.business-unit-3-folders-tree.second_level_folders_service_account_keys
}

output "business_unit_3_envs_service_accounts" {
  description = "Service accounts used to run each environment Terraform modules for business unit 3."
  value       = module.business-unit-3-folders-tree.second_level_folders_service_account_emails
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