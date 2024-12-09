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
  ngfw_dev_locations = toset([
    for k, v in var.cas_configs.dev : v.location
    if contains(var.ngfw_tls_configs.keys.dev.cas, k)
  ])
}

module "dev-sec-project" {
  source = "../../../modules/project"
  name   = "dev-sec-core-0"
  factories_config = {
    logging_metrics_alerts = var.factories_config.logging_metrics_alerts
  }
  default_alerts_email = var.default_alerts_email
  parent = coalesce(
    var.folder_ids.security-dev, var.folder_ids.security
  )
  prefix          = var.prefix
  billing_account = var.billing_account.id
  labels          = { environment = "dev" }
  services        = local.project_services
  tag_bindings = local.has_env_folders ? {} : {
    environment = local.env_tag_values["dev"]
  }
  # optionally delegate a fixed set of IAM roles to selected principals
  iam = {
    (var.custom_roles.project_iam_viewer) = try(local.iam_viewer_principals["dev"], [])
  }
  iam_bindings = (
    lookup(local.iam_delegated_principals, "dev", null) == null ? {} : {
      sa_delegated_grants = {
        role    = "roles/resourcemanager.projectIamAdmin"
        members = try(local.iam_delegated_principals["dev"], [])
        condition = {
          title       = "dev_stage3_sa_delegated_grants"
          description = "${var.environments["dev"].name} project delegated grants."
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            local.iam_delegated
          )
        }
      }
    }
  )
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

module "dev-cas" {
  for_each       = var.cas_configs.dev
  source         = "../../../modules/certificate-authority-service"
  project_id     = module.dev-sec-project.project_id
  ca_configs     = each.value.ca_configs
  ca_pool_config = each.value.ca_pool_config
  iam            = each.value.iam
  iam_bindings   = each.value.iam_bindings
  iam_bindings_additive = (
    contains(var.ngfw_tls_configs.keys.dev.cas, each.key)
    ? merge(
      {
        nsec_agent = {
          member = module.dev-sec-project.service_agents["networksecurity"].iam_email
          role   = "roles/privateca.certificateManager"
        }
      },
      each.value.iam_bindings_additive
    )
    : each.value.iam_bindings_additive
  )
  iam_by_principals = each.value.iam_by_principals
  location          = each.value.location
}

resource "google_certificate_manager_trust_config" "dev_trust_configs" {
  for_each    = var.trust_configs.dev
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

resource "google_network_security_tls_inspection_policy" "ngfw_dev_tls_ips" {
  for_each = (
    var.ngfw_tls_configs.tls_inspection.enabled
    ? local.ngfw_dev_locations : toset([])
  )
  name     = "${var.prefix}-dev-tls-ip-0"
  project  = module.dev-sec-project.project_id
  location = each.key
  ca_pool = try([
    for k, v in module.dev-cas
    : v.ca_pool_id
    if v.ca_pool.location == each.key && contains(var.ngfw_tls_configs.keys.dev.cas, k)
  ][0], null)
  exclude_public_ca_set = var.ngfw_tls_configs.tls_inspection.exclude_public_ca_set
  min_tls_version       = var.ngfw_tls_configs.tls_inspection.min_tls_version
  trust_config = try([
    for k, v in google_certificate_manager_trust_config.dev_trust_configs
    : v.id
    if v.location == each.key
  ][0], null)
}
