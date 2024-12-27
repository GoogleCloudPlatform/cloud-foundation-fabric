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

# tfdoc:file:description Per-environment certificate resources.

locals {
  cas = flatten([
    for k, v in var.certificate_authorities : [
      for e in coalesce(v.environments, keys(var.environments)) : merge(v, {
        environment = e
        key         = "${e}-${k}"
        name        = k
        netsec_iam  = contains(var.trust_configs.keys.dev.cas, k)
      })
    ]
  ])
  trust_configs = flatten([
    for k, v in var.trust_configs : [
      for e in coalesce(v.environments, keys(var.environments)) : merge(v, {
        environment = e
        key         = "${e}-${k}"
        name        = k
      })
    ]
  ])
}

module "cas" {
  source         = "../../../modules/certificate-authority-service"
  for_each       = { for k in local.cas : k.key => k }
  project_id     = module.project[each.value.environment].project_id
  ca_configs     = each.value.ca_configs
  ca_pool_config = each.value.ca_pool_config
  iam            = each.value.iam
  iam_bindings   = each.value.iam_bindings
  iam_bindings_additive = merge(
    each.value.iam_bindings_additive,
    !each.value.netsec_iam ? {} : {
      nsec_agent = {
        member = module.project[each.value.environment].service_agents["networksecurity"].iam_email
        role   = "roles/privateca.certificateManager"
      }
  })
  iam_by_principals = each.value.iam_by_principals
  location          = each.value.location
}

resource "google_certificate_manager_trust_config" "default" {
  for_each    = { for k in local.trust_configs : k.key => k }
  name        = each.value.name
  project     = module.project[each.value.environment].project_id
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
