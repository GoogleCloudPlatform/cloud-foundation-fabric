/**
 * Copyright 2025 Google LLC
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

locals {
  _o_kms_keys = flatten([
    for k, v in module.kms : [
      for name, id in v.key_ids : {
        key = "${name}-${k}"
        id  = id
      }
    ]
  ])
  tfvars = {
    security_project_ids     = module.factory.project_ids
    security_project_numbers = module.factory.project_numbers
    ca_pools = {
      for k, v in module.cas : k => {
        ca_ids   = v.ca_ids
        id       = v.ca_pool_id
        location = v.ca_pool.location
      }
    }
    kms_keys = {
      for k in local._o_kms_keys : k.key => k.id
    }
  }
}

resource "google_storage_bucket_object" "version" {
  count = (
    local.output_files.storage_bucket != null &&
    fileexists("fast_version.txt") ? 1 : 0
  )
  bucket = local.output_files.storage_bucket
  name   = "versions/${local.defaults.stage_name}-version.txt"
  source = "fast_version.txt"
}

resource "local_file" "tfvars" {
  for_each        = local.output_files.local_path == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(local.output_files.local_path)}/tfvars/${local.defaults.stage_name}.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  count   = local.output_files.storage_bucket != null ? 1 : 0
  bucket  = local.output_files.storage_bucket
  name    = "tfvars/${local.defaults.stage_name}.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

output "ca_pools" {
  description = "Certificate Authority Service pools and CAs."
  value       = local.tfvars.ca_pools
}

output "kms_keys_ids" {
  description = "KMS keys IDs."
  value       = local.tfvars.kms_keys
}

output "security_project_ids" {
  description = "Security project IDs."
  value       = local.tfvars.security_project_ids
}

output "security_project_numbers" {
  description = "Security project numbers."
  value       = local.tfvars.security_project_numbers
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
