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

# tfdoc:file:description Workload Identity Federation provider definitions.

locals {
  workload_identity_providers = {
    for k, v in var.workload_identity_providers : k => merge(
      v,
      lookup(local.workload_identity_providers_defs, v.issuer, {})
    )
  }
}

resource "google_iam_workload_identity_pool" "default" {
  provider = google-beta
  count    = length(local.workload_identity_providers) > 0 ? 1 : 0
  project  = module.automation-project.project_id
  workload_identity_pool_id = templatestring(
    var.resource_names["wif-bootstrap"], { prefix = var.prefix }
  )
}

resource "google_iam_workload_identity_pool_provider" "default" {
  provider = google-beta
  for_each = local.workload_identity_providers
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default[0].workload_identity_pool_id
  )
  workload_identity_pool_provider_id = templatestring(
    var.resource_names["wif-provider_template"], {
      prefix = var.prefix
      key    = each.key
  })
  attribute_condition = each.value.attribute_condition
  attribute_mapping   = each.value.attribute_mapping
  oidc {
    # Setting an empty list configures allowed_audiences to the url of the provider
    allowed_audiences = each.value.custom_settings.audiences
    # If users don't provide an issuer_uri, we set the public one for the platform chosen.
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
