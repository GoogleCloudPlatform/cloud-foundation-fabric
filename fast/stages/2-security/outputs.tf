/**
 * Copyright 2024 Google LLC
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
  _output_kms_keys = concat(
    flatten([
      for location, mod in module.dev-sec-kms : [
        for name, id in mod.key_ids : {
          key = "dev-${name}:${location}"
          id  = id
        }
      ]
    ]),
    flatten([
      for location, mod in module.prod-sec-kms : [
        for name, id in mod.key_ids : {
          key = "prod-${name}:${location}"
          id  = id
        }
      ]
    ])
  )
  cas_configs = {
    dev = {
      for k, v in module.dev-cas
      : k => {
        ca_pool_id = v.ca_pool_id
        ca_ids     = v.ca_ids
        location   = v.ca_pool.location
      }
    }
    prod = {
      for k, v in module.prod-cas
      : k => {
        ca_pool_id = v.ca_pool_id
        ca_ids     = v.ca_ids
        location   = v.ca_pool.location
      }
    }
  }
  ngfw_tls_configs = {
    tls_enabled = var.ngfw_tls_configs.tls_inspection.enabled
    tls_ip_ids_by_region = {
      dev = {
        for k, v in google_network_security_tls_inspection_policy.ngfw_dev_tls_ips
        : v.location => v.id
      }
      prod = {
        for k, v in google_network_security_tls_inspection_policy.ngfw_prod_tls_ips
        : v.location => v.id
      }
    }
  }
  output_kms_keys = { for k in local._output_kms_keys : k.key => k.id }
  tfvars = {
    cas_configs      = local.cas_configs
    kms_keys         = local.output_kms_keys
    ngfw_tls_configs = local.ngfw_tls_configs
    trust_config_ids = local.trust_config_ids
  }
  trust_config_ids = {
    dev = {
      for k, v in google_certificate_manager_trust_config.dev_trust_configs
      : k => v.id
    }
    prod = {
      for k, v in google_certificate_manager_trust_config.prod_trust_configs
      : k => v.id
    }
  }
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/2-security.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/2-security.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

output "cas_configs" {
  description = "Certificate Authority Service configurations."
  value       = local.cas_configs
}

output "kms_keys" {
  description = "KMS key ids."
  value       = local.output_kms_keys
}

output "ngfw_tls_configs" {
  description = "The NGFW Enterprise configurations."
  value       = local.ngfw_tls_configs
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

output "trust_config_ids" {
  description = "Certificate Manager trust-config ids."
  value       = local.trust_config_ids
}
