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
  _ngfw_cas_config_prod = {
    prod-ca-0 = {
      ca_configs = {
        prod-root-ngfw-ca-0 = {
          deletion_protection = false #delete
          subject = {
            common_name  = try(var.ngfw_tls_configs.prod.cas_config.common_name, null)
            organization = try(var.ngfw_tls_configs.prod.cas_config.organization, null)
          }
        }
      }
      ca_pool_config = {
        authz_nsec_sa = true
        name          = "prod-ngfw-ca-pool-3" #fix
      }
      iam          = {}
      iam_bindings = {}
      iam_bindings_additive = {
        nsec_prod_sa_binding = {
          member = module.prod-sec-project.service_agents["networksecurity"].iam_email
          role   = "roles/privateca.certificateManager"
        }
      }
      iam_by_principals = {}
      location          = var.ngfw_tls_configs.prod.location
    }
  }
  _ngfw_trust_config_prod = {
    prod-trust-0 = merge(
      { location = var.ngfw_tls_configs.prod.location },
      var.ngfw_tls_configs.prod.trust_config
    )
  }
  cas_config_prod = merge(
    var.cas_configs.prod,
    try(var.ngfw_tls_configs.prod.cas_config, null) != null
    ? local._ngfw_cas_config_prod : null
  )
  prod_kms_restricted_admins = [
    for sa in distinct(compact([
      var.service_accounts.data-platform-prod,
      var.service_accounts.project-factory,
      var.service_accounts.project-factory-prod
    ])) : "serviceAccount:${sa}"
  ]
  trust_config_prod = merge(
    var.trust_configs.prod,
    try(var.ngfw_tls_configs.prod.trust_config, null) != null
    ? local._ngfw_trust_config_prod : null
  )
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

module "prod-sec-cas" {
  for_each              = local.cas_config_prod
  source                = "../../../modules/certificate-authority-service"
  project_id            = module.prod-sec-project.project_id
  ca_configs            = each.value.ca_configs
  ca_pool_config        = each.value.ca_pool_config
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  location              = each.value.location
}

resource "google_certificate_manager_trust_config" "prod_trust_configs" {
  for_each    = local.trust_config_prod
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
