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
  _ngfw_dev_cas_iam_bindings_additive = {
    nsec_dev_sa_binding = {
      member = module.dev-sec-project.service_agents["networksecurity"].iam_email
      role   = "roles/privateca.certificateManager"
    }
  }
  _ngfw_cas_config_dev = {
    for k, v in var.ngfw_tls_configs.dev.cas_configs
    : k => merge(
      v,
      _ngfw_dev_cas_iam_bindings_additive
    ) if 
  }
  cas_config_dev = merge(
    var.cas_configs.dev,
    try(var.ngfw_tls_configs.dev.cas_config, null) != null
    ? local._ngfw_cas_config_dev : null
  )
  dev_kms_restricted_admins = [
    for sa in distinct(compact([
      var.service_accounts.data-platform-dev,
      var.service_accounts.project-factory,
      var.service_accounts.project-factory-dev,
      var.service_accounts.project-factory-prod
    ])) : "serviceAccount:${sa}"
  ]
  trust_config_dev = merge(
    var.trust_configs.dev,
    try(var.ngfw_tls_configs.dev.trust_config, null) != null
    ? local._ngfw_trust_config_dev : null
  )
}

module "dev-sec-project" {
  source          = "../../../modules/project"
  name            = "dev-sec-core-0"
  parent          = var.folder_ids.security
  prefix          = var.prefix
  billing_account = var.billing_account.id
  iam = {
    "roles/cloudkms.viewer" = local.dev_kms_restricted_admins
  }
  iam_bindings_additive = {
    for member in local.dev_kms_restricted_admins :
    "kms_restricted_admin.${member}" => merge(local.kms_restricted_admin_template, {
      member = member
    })
  }
  labels   = { environment = "dev", team = "security" }
  services = local.project_services
}

module "dev-sec-kms" {
  for_each   = toset(local.kms_locations)
  source     = "../../../modules/kms"
  project_id = module.dev-sec-project.project_id
  keyring = {
    location = each.key
    name     = "dev-${each.key}"
  }
  keys = local.kms_locations_keys[each.key]
}

module "dev-sec-cas" {
  for_each              = local.cas_config_dev
  source                = "../../../modules/certificate-authority-service"
  project_id            = module.dev-sec-project.project_id
  ca_configs            = each.value.ca_configs
  ca_pool_config        = each.value.ca_pool_config
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  location              = each.value.location
}

resource "google_certificate_manager_trust_config" "dev_trust_configs" {
  for_each    = local.trust_config_dev
  name        = each.key
  project     = module.dev-sec-project.project_id
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
