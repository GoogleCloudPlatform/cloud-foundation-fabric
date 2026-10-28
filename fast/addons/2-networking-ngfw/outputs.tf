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
  _o_cas = flatten([
    for k, v in local._cas_modules : [
      for name, chain in v.ca_chains : {
        chain = chain
        key   = "${k}-${name}"
      }
    ]
  ])
  ca_chains = {
    for k in local._o_cas : k.key => k.chain
  }
  security_profile_group_ids = {
    for k, v in google_network_security_security_profile_group.default :
    k => "//networksecurity.googleapis.com/${v.id}"
  }
  tfvars = {
    ca_chains = local.ca_chains
    ngfw = {
      associations = {
        for k, v in google_network_security_firewall_endpoint_association.default :
        k => v.id
      }
      endpoints = {
        for k, v in google_network_security_firewall_endpoint.default : k => v.id
      }
    }
    security_profile_groups = local.security_profile_group_ids
  }
}

resource "local_file" "ca_chains" {
  for_each        = var.outputs_location == null ? {} : local.ca_chains
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/ca-chains/${var.names.output_files_prefix}/${each.key}.pem"
  content         = each.value
}

resource "google_storage_bucket_object" "ca_chains" {
  for_each = local.ca_chains
  bucket   = var.automation.outputs_bucket
  name     = "ca-chains/${var.names.output_files_prefix}/${each.key}.pem"
  content  = each.value
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/${var.names.output_files_prefix}.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/${var.names.output_files_prefix}.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}
