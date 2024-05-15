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

# tfdoc:file:description Workload Identity Federation provider definitions.

locals {
  workforce_identity_providers = {
    for k, v in var.workforce_identity_providers : k => merge(
      v,
      lookup(local.workforce_identity_providers_defs, v.issuer, {})
    )
  }
  workload_identity_providers = {
    for k, v in var.workload_identity_providers : k => merge(
      v,
      lookup(local.workload_identity_providers_defs, v.issuer, {})
    )
  }
}

resource "google_iam_workforce_pool" "default" {
  count             = length(local.workforce_identity_providers) > 0 ? 1 : 0
  parent            = "organizations/${var.organization.id}"
  location          = "global"
  workforce_pool_id = "${var.prefix}-bootstrap"
}

resource "google_iam_workforce_pool_provider" "default" {
  for_each            = local.workforce_identity_providers
  attribute_condition = each.value.attribute_condition
  attribute_mapping   = each.value.attribute_mapping
  description         = each.value.description
  disabled            = each.value.disabled
  display_name        = each.value.display_name
  location            = google_iam_workforce_pool.default[0].location
  provider_id         = "${var.prefix}-bootstrap-${each.key}"
  workforce_pool_id   = google_iam_workforce_pool.default[0].workforce_pool_id
  saml {
    idp_metadata_xml = each.value.saml.idp_metadata_xml
  }
}

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  count                     = length(local.workload_identity_providers) > 0 ? 1 : 0
  project                   = module.automation-project.project_id
  workload_identity_pool_id = "${var.prefix}-bootstrap"
}

resource "google_iam_workload_identity_pool_provider" "default" {
  provider = google-beta
  for_each = local.workload_identity_providers
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default[0].workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-bootstrap-${each.key}"
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  oidc {
    # Setting an empty list configures allowed_audiences to the url of the provider
    allowed_audiences = each.value.custom_settings.audiences
    # If users don't provide an issuer_uri, we set the public one for the platform choosed.
    issuer_uri = (
      each.value.custom_settings.issuer_uri != null
      ? each.value.custom_settings.issuer_uri
      : try(each.value.issuer_uri, null)
    )
    # OIDC JWKs in JSON String format. If no value is provided, they key is
    # fetched from the `.well-known` path for the issuer_uri
    jwks_json = each.value.custom_settings.jwks_json
  }
}
