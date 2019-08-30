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

output "top_level_folder_id" {
  description = "Top-level folder ID."
  value       = module.top-level-folder.id
}

output "second_level_folders_ids" {
  description = "Second-level folders IDs."
  value       = module.second-level-folders.ids
}

output "second_level_folders_tf_gcs_bucket_names" {
  description = "GCS buckets used for each second-level folder Terraform state."
  value       = module.gcs-tf-second-level-folders.names
}

output "second_level_folders_service_account_keys" {
  description = "Service account keys used to run each second-level folder Terraform modules."
  sensitive   = true
  value       = module.service-accounts-tf-second-level-folders.keys
}

output "second_level_folders_service_account_emails" {
  description = "Service accounts used to run each econd-level folder Terraform modules."
  value       = module.service-accounts-tf-second-level-folders.emails
}

# Add further outputs here for the additional modules that manage shared
# resources, like GCR, GCS buckets, KMS, etc.
