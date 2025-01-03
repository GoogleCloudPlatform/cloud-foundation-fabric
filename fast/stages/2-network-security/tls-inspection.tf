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
  tls_projects = distinct([
    for k, v in var.trust_configs : {
      key   = v.project_id
      value = lookup(var.host_project_ids, v.project_id, null)
    } if lookup(var.host_project_ids, v.project_id, null) != null
  ])
}

module "tls-project" {
  source         = "../../../modules/project"
  for_each       = { for v in local.tls_projects : v.key => v.value }
  name           = each.value
  project_create = false
  services = [
    "certificatemanager.googleapis.com"
  ]
}

resource "google_certificate_manager_trust_config" "default" {
  for_each = var.trust_configs
  project = try(
    module.tls-project[each.value.project_id].project_id,
    each.value.project_id
  )
  name        = each.key
  description = each.value.description
  location    = lookup(var.regions, each.value.location, each.value.location)

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
