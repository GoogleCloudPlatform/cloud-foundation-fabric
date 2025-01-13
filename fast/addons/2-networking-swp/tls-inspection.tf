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
  # extract SWP project ids for each CA internally created by SWP configurations
  _swp_cas = {
    for k, v in var.swp_configs :
    try(v.tls_inspection_config.create_config.ca_pool, null) => v.project_id...
  }
  # determine which CAs are actually referenced from SWP configurations
  ca_active = {
    for k, v in var.certificate_authorities : k => merge(v, {
      swp_projects = toset(distinct(lookup(local._swp_cas, k, [])))
    }) if lookup(local._swp_cas, k, null) != null
  }
  ca_pool_ids = { for k, v in var.certificate_authority_pools : k => v.id }
}

module "cas" {
  source         = "../../../modules/certificate-authority-service"
  for_each       = local.ca_active
  project_id     = module.projects-cas[each.value.project_id].project_id
  location       = each.value.location
  ca_configs     = each.value.ca_configs
  ca_pool_config = each.value.ca_pool_config
  iam            = each.value.iam
  iam_bindings   = each.value.iam_bindings
  iam_bindings_additive = merge(
    each.value.iam_bindings_additive,
    var._fast_debug.skip_datasources == true ? {} : {
      for p in each.value.swp_projects : "nsec_${p}" => {
        member = module.projects-swp[p].service_agents["networksecurity"].iam_email
        role   = "roles/privateca.certificateManager"
      }
    }
  )
  iam_by_principals = each.value.iam_by_principals
}

resource "google_network_security_tls_inspection_policy" "default" {
  for_each = {
    for k, v in var.swp_configs : k => v
    if try(v.tls_inspection_config.create_config, null) != null
  }
  project               = module.projects-swp[each.value.project_id].project_id
  name                  = "${each.key}-${var.base_name}"
  location              = each.value.region
  exclude_public_ca_set = each.value.exclude_public_ca_set
  ca_pool               = lookup(local.ca_pool_ids, each.value.ca_pool, each.value.ca_pool)
  custom_tls_features   = each.value.tls.custom_features
  tls_feature_profile   = each.value.tls.feature_profile
  min_tls_version       = each.value.tls.min_version
}
