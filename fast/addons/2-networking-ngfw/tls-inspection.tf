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

# tfdoc:file:description TLS inspection policies and supporting resources.

locals {
  ca_pool_ids = merge(
    { for k, v in var.certificate_authority_pools : k => v.id },
    { for k, v in module.cas : k => v.ca_pool_id }
  )
  trust_config_ids = {
    for k, v in google_certificate_manager_trust_config.default : k => v.id
  }
}

module "cas" {
  source     = "../../../modules/certificate-authority-service"
  for_each   = var.certificate_authorities
  project_id = local.project_id
  ca_configs = each.value.ca_configs
  ca_pool_config = (
    each.value.ca_pool_config != null
    ? each.value.ca_pool_config
    : {
      create_pool = {
        name = each.key
      }
    }
  )
  iam          = each.value.iam
  iam_bindings = each.value.iam_bindings
  iam_bindings_additive = merge(
    each.value.iam_bindings_additive,
    var._fast_debug.skip_datasources == true ? {} : {
      nsec_certificate_manager = {
        member = module.project[0].service_agents["networksecurity"].iam_email
        role   = "roles/privateca.certificateManager"
      }
    }
  )
  iam_by_principals = each.value.iam_by_principals
  location          = each.value.location
}

resource "google_certificate_manager_trust_config" "default" {
  for_each    = var.trust_configs
  project     = local.project_id
  name        = each.key
  description = each.value.description
  location    = each.value.location
  dynamic "allowlisted_certificates" {
    for_each = each.value.allowlisted_certificates
    content {
      pem_certificate = file(allowlisted_certificates.value)
    }
  }
  dynamic "trust_stores" {
    for_each = each.value.trust_stores
    content {
      dynamic "intermediate_cas" {
        for_each = trust_stores.value.intermediate_cas
        content {
          pem_certificate = file(intermediate_cas.value)
        }
      }
      dynamic "trust_anchors" {
        for_each = trust_stores.value.trust_anchors
        content {
          pem_certificate = file(trust_anchors.value)
        }
      }
    }
  }
}

resource "google_network_security_tls_inspection_policy" "default" {
  for_each              = var.tls_inspection_policies
  project               = local.project_id
  name                  = each.key
  location              = each.value.location
  exclude_public_ca_set = each.value.exclude_public_ca_set
  ca_pool = lookup(
    local.ca_pool_ids, each.value.ca_pool_id, each.value.ca_pool_id
  )
  trust_config = lookup(
    local.trust_config_ids, each.value.trust_config, each.value.trust_config
  )
  custom_tls_features = each.value.tls.custom_features
  tls_feature_profile = each.value.tls.feature_profile
  min_tls_version     = each.value.tls.min_version
}
