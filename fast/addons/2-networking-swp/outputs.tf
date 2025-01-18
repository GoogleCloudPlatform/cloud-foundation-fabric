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
  tfvars = {
    swp_cas_pool_ids = {
      for k, v in module.cas : k => v.ca_pool_id
    }
    swp_gateway_ids = {
      for k, v in module.swp : k => v.id
    }
    swp_gateway_security_policy_ids = {
      for k, v in module.swp : k => v.gateway_security_policy
    }
    swp_service_attachment_ids = {
      for k, v in module.swp : k => v.service_attachment
    }
  }
}

output "cas_pool_ids" {
  description = "Certificate Authority Service pool ids."
  value       = local.tfvars.swp_cas_pool_ids
}

output "gateway_security_policies" {
  description = "The gateway security policy resources."
  value       = local.tfvars.swp_gateway_security_policy_ids
}

output "gateways" {
  description = "The gateway resources."
  value       = { for k, v in module.swp : k => v.gateway }
}

output "ids" {
  description = "Gateway IDs."
  value       = local.tfvars.swp_gateway_ids
}

output "service_attachments" {
  description = "Service attachment IDs."
  value       = local.tfvars.swp_service_attachment_ids
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-networking-${var.name}.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/2-networking-${var.name}.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}
