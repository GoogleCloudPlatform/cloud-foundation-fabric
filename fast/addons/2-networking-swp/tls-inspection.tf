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

module "cas" {
  source     = "../../../modules/certificate-authority-service"
  for_each   = var.certificate_authority == null ? {} : local.regions
  project_id = local.project_id
  location   = each.value
  ca_configs = var.certificate_authority.ca_configs
  ca_pool_config = (
    var.certificate_authority.ca_pool_config != null
    ? var.certificate_authority.ca_pool_config
    : {
      create_pool = {
        name = "${var.name}-${each.key}"
      }
    }
  )
  iam               = var.certificate_authority.iam
  iam_by_principals = var.certificate_authority.iam_by_principals
  iam_bindings      = var.certificate_authority.iam_bindings
  iam_bindings_additive = merge(
    var.certificate_authority.iam_bindings_additive,
    var._fast_debug.skip_datasources == true ? {} : {
      nsec_certificate_manager = {
        member = module.project[0].service_agents["networksecurity"].iam_email
        role   = "roles/privateca.certificateManager"
      }
    }
  )
}

resource "google_network_security_tls_inspection_policy" "default" {
  for_each              = var.tls_inspection_policy == null ? {} : local.regions
  project               = local.project_id
  name                  = "${var.name}-${each.key}"
  location              = each.value
  exclude_public_ca_set = var.tls_inspection_policy.exclude_public_ca_set
  ca_pool = (
    var.tls_inspection_policy.ca_pool_id == null
    ? module.cas[each.key].ca_pool_id
    : var.tls_inspection_policy.ca_pool_id
  )
  custom_tls_features = try(var.tls_inspection_policy.tls.custom_features, null)
  tls_feature_profile = try(var.tls_inspection_policy.tls.feature_profile, null)
  min_tls_version     = try(var.tls_inspection_policy.tls.min_version, null)
}
