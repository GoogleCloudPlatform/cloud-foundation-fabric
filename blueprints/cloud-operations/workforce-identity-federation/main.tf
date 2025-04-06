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

# tfdoc:file:description Workforce Identity Federation pools and providers.

locals {
  _workforce_identity_providers = flatten([
    for k, v in var.workforce_identity_pools : [
      for i, d in v.providers : merge({
        pool_id             = k
        provider_id         = i
        disabled            = d.disabled
        description         = d.description
        attribute_condition = d.attribute_condition
        saml_metadata_url   = d.saml_metadata_url
      },
      local.workforce_identity_providers_defs[d.issuer])
    ]
  ])
  workforce_identity_providers = tomap({
    for d in local._workforce_identity_providers : "${d.pool_id}.${d.provider_id}" => 
      d if d.saml_metadata_url != null
  })
}

resource "google_iam_workforce_pool" "default" {
  for_each = var.workforce_identity_pools
  parent   = "organizations/${var.organization.id}"
  location = each.value.location
  disabled = each.value.disabled

  workforce_pool_id   = "${var.prefix}-${each.key}"
  display_name        = each.value.display_name == null ? "${var.prefix}-${each.key}" : each.value.display_name
  description         = each.value.description
  session_duration    = each.value.session_duration

  dynamic "access_restrictions" {
    for_each = each.value.access_restrictions != null ? [1] : []
    content {
      dynamic "allowed_services" {
        for_each = try(each.value.access_restrictions.allowed_domains, [])
        content {
          domain = allowed_services.value
        }
      }
      disable_programmatic_signin = try(
        each.value.access_restrictions.disable_programmatic_signin, 
        null
      )
    }
  }
}

resource "google_iam_workforce_pool_provider" "default" {
  for_each            = local.workforce_identity_providers
  attribute_condition = each.value.attribute_condition
  attribute_mapping   = each.value.attribute_mapping
  description         = each.value.description
  disabled            = each.value.disabled
  display_name        = try(each.value.display_name, "${var.prefix}-${each.value.provider_id}")
  location            = google_iam_workforce_pool.default[each.value.pool_id].location
  provider_id         = "${var.prefix}-${each.value.provider_id}"
  workforce_pool_id   = google_iam_workforce_pool.default[each.value.pool_id].workforce_pool_id
  
  saml {
    idp_metadata_xml = data.http.saml_metadata_xml[each.key].response_body
  }
}