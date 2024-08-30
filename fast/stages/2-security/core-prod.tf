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
  # Extract NGFW locations from prod CAS
  ngfw_prod_locations = toset([
    for k, v in var.cas_configs.prod
    : v.location
    if contains(var.ngfw_tls_configs.keys.prod.cas, k)
  ])
  ngfw_prod_sa_agent_cas_iam_bindings_additive = {
    nsec_prod_agent_sa_binding = {
      member = module.prod-sec-project.service_agents["networksecurity"].iam_email
      role   = "roles/privateca.certificateManager"
    }
  }
  prod_kms_restricted_admins = [
    for sa in distinct(compact([
      var.service_accounts.data-platform-prod,
      var.service_accounts.project-factory,
      var.service_accounts.project-factory-prod
    ])) : "serviceAccount:${sa}"
  ]
}

module "prod-sec-project" {
  source          = "../../../modules/project"
  name            = "prod-sec-core-0"
  parent          = var.folder_ids.security
  prefix          = var.prefix
  billing_account = var.billing_account.id
  iam = {
    "roles/cloudkms.viewer" = local.prod_kms_restricted_admins
  }
  iam_bindings_additive = {
    for member in local.prod_kms_restricted_admins :
    "kms_restricted_admin.${member}" => merge(local.kms_restricted_admin_template, {
      member = member
    })
  }
  labels   = { environment = "prod", team = "security" }
  services = local.project_services
}

module "prod-sec-kms" {
  for_each   = toset(local.kms_locations)
  source     = "../../../modules/kms"
  project_id = module.prod-sec-project.project_id
  keyring = {
    location = each.key
    name     = "prod-${each.key}"
  }
  keys = local.kms_locations_keys[each.key]
}

module "prod-cas" {
  for_each       = var.cas_configs.prod
  source         = "../../../modules/certificate-authority-service"
  project_id     = module.prod-sec-project.project_id
  ca_configs     = each.value.ca_configs
  ca_pool_config = each.value.ca_pool_config
  iam            = each.value.iam
  iam_bindings   = each.value.iam_bindings
  iam_bindings_additive = (
    contains(var.ngfw_tls_configs.keys.prod.cas, each.key)
    ? merge(local.ngfw_prod_sa_agent_cas_iam_bindings_additive, each.value.iam_bindings_additive)
    : each.value.iam_bindings_additive
  )
  iam_by_principals = each.value.iam_by_principals
  location          = each.value.location
}

resource "google_certificate_manager_trust_config" "prod_trust_configs" {
  for_each    = var.trust_configs.prod
  name        = each.key
  project     = module.prod-sec-project.project_id
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

resource "google_network_security_tls_inspection_policy" "ngfw_prod_tls_ips" {
  for_each = (
    var.ngfw_tls_configs.tls_inspection.enabled
    ? local.ngfw_prod_locations : toset([])
  )
  name     = "${var.prefix}-prod-tls-ip-0"
  project  = module.prod-sec-project.project_id
  location = each.key
  ca_pool = try([
    for k, v in module.prod-cas
    : v.ca_pool_id
    if v.ca_pool.location == each.key && contains(var.ngfw_tls_configs.keys.prod.cas, k)
  ][0], null)
  exclude_public_ca_set = var.ngfw_tls_configs.tls_inspection.exclude_public_ca_set
  min_tls_version       = var.ngfw_tls_configs.tls_inspection.min_tls_version
  trust_config = try([
    for k, v in google_certificate_manager_trust_config.prod_trust_configs
    : v.id
    if v.location == each.key
  ][0], null)
}

