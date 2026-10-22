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
  _o_cas_modules = merge(module.cas, module.cas-subordinate)
  _o_cas = flatten([
    for k, v in local._o_cas_modules : [
      for name, id in v.ca_ids : {
        chain = v.ca_chains[name]
        id    = id
        key   = "${k}-${name}"
      }
    ]
  ])
  _o_kms_keys = flatten([
    for k, v in module.kms : [
      for name, id in v.key_ids : {
        key = "${name}-${k}"
        id  = id
      }
    ]
  ])
  tfvars = {
    ca_chains = {
      for k in local._o_cas : k.key => k.chain
    }
    ca_ids = {
      for k in local._o_cas : k.key => k.id
    }
    ca_pools = {
      for k, v in local._o_cas_modules : k => v.ca_pool_id
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
  bucket         = local.output_files.storage_bucket
  name           = "versions/${local.defaults.stage_name}-version.txt"
  source         = "fast_version.txt"
  source_md5hash = filemd5("fast_version.txt")
}

resource "local_file" "ca_chains" {
  for_each        = local.output_files.local_path == null ? {} : local.tfvars.ca_chains
  file_permission = "0644"
  filename        = "${pathexpand(local.output_files.local_path)}/ca-chains/${local.defaults.stage_name}/${each.key}.pem"
  content         = each.value
}

resource "google_storage_bucket_object" "ca_chains" {
  for_each = local.output_files.storage_bucket == null ? {} : local.tfvars.ca_chains
  bucket   = local.output_files.storage_bucket
  name     = "ca-chains/${local.defaults.stage_name}/${each.key}.pem"
  content  = each.value
}

resource "local_file" "tfvars" {
  for_each        = local.output_files.local_path == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(local.output_files.local_path)}/tfvars/${local.defaults.stage_name}.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  count          = local.output_files.storage_bucket != null ? 1 : 0
  bucket         = local.output_files.storage_bucket
  name           = "tfvars/${local.defaults.stage_name}.auto.tfvars.json"
  content        = jsonencode(local.tfvars)
  source_md5hash = md5(jsonencode(local.tfvars))
}

output "ca_ids" {
  description = "Certificate Authority Service CA IDs."
  value       = local.tfvars.ca_ids
}

output "ca_pools" {
  description = "Certificate Authority Service pool IDs."
  value       = local.tfvars.ca_pools
}

output "kms_keys_ids" {
  description = "KMS keys IDs."
  value       = local.tfvars.kms_keys
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
