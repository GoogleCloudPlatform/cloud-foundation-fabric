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
  value       = module.tf-project.project_id
}

output "bootstrap_tf_gcs_bucket" {
  description = "GCS bucket used for the bootstrap Terraform state."
  value       = module.tf-gcs-bootstrap.name
}

output "shared_folder_id" {
  description = "Shared folder ID."
  value       = module.shared-folder.id
}

output "bu_ml" {
  description = "Business Unit ML attributes."
  value = module.busines-unit-ml.unit
}

output "bu_ml_sa_keys" {
  description = "Business Unit ML Service Accoutns keys."
  sensitive = true
  value = module.busines-unit-ml.keys
}

output "bu_bi" {
  description = "Business Unit BI attributes."
  value = module.busines-unit-bi.unit
}

output "bu_bi_sa_keys" {
  description = "Business Unit BI Service Accoutns keys."
  sensitive = true
  value = module.busines-unit-bi.keys
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