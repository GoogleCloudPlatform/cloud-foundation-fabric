/**
 * Copyright 2021 Google LLC
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

output "terraform_project" {
  description = "Project that holds the base Terraform resources."
  value       = module.tf-project.project_id
}

output "bootstrap_tf_gcs_bucket" {
  description = "GCS bucket used for the bootstrap Terraform state."
  value       = module.tf-gcs-bootstrap.name
}

output "shared_folder_id" {
  description = "Shared folder id."
  value       = module.shared-folder.id
}

output "bu_machine_learning" {
  description = "Machine Learning attributes."
  value = {
    unit_folder          = module.bu-machine-learning.unit_folder,
    env_gcs_buckets      = module.bu-machine-learning.env_gcs_buckets
    env_folders          = module.bu-machine-learning.env_folders
    env_service_accounts = module.bu-machine-learning.env_service_accounts
  }
}

output "bu_machine_learning_keys" {
  description = "Machine Learning service account keys."
  sensitive   = true
  value       = module.bu-machine-learning.env_sa_keys
}

output "bu_business_intelligence" {
  description = "Business Intelligence attributes."
  value = {
    unit_folder          = module.bu-business-intelligence.unit_folder,
    env_gcs_buckets      = module.bu-business-intelligence.env_gcs_buckets
    env_folders          = module.bu-business-intelligence.env_folders
    env_service_accounts = module.bu-business-intelligence.env_service_accounts
  }
}

output "bu_business_intelligence_keys" {
  description = "Business Intelligence service account keys."
  sensitive   = true
  value       = module.bu-business-intelligence.env_sa_keys
}

output "audit_logs_project" {
  description = "Project that holds the audit logs export resources."
  value       = module.audit-project.project_id
}

output "shared_resources_project" {
  description = "Project that holdes resources shared across business units."
  value       = module.shared-project.project_id
}

# Add further outputs here for the additional modules that manage shared
# resources, like GCR, GCS buckets, KMS, etc.
