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

# tfdoc:file:description Per-tenant Workload Identity Federation providers.

locals {
  # flatten tenant provider configurations into a single list and derive key
  _workload_identity_providers = flatten([
    for k, v in local.fast_tenants : [
      for pk, pv in v.fast_config.workload_identity_providers : merge(
        pv,
        lookup(local.workload_identity_providers_defs, pv.issuer, {}),
        {
          key      = "${k}-${pk}"
          prefix   = v.prefix
          provider = pk
          tenant   = k
        }
      )
    ]
  ])
  # identify FAST tenants with WIF configurations
  workload_identity_pools = {
    for k, v in local.fast_tenants : k => v.prefix
    if length(v.fast_config.workload_identity_providers) > 0
  }
  # reconstitute all tenant provider configurations as a map
  workload_identity_providers = {
    for v in local._workload_identity_providers : v.key => v
  }
}

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  for_each                  = local.workload_identity_pools
  project                   = module.tenant-automation-project[each.key].project_id
  workload_identity_pool_id = "${each.value}-bootstrap"
}

resource "google_iam_workload_identity_pool_provider" "default" {
  provider = google-beta
  for_each = local.workload_identity_providers
  project  = module.tenant-automation-project[each.value.tenant].project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default[each.value.tenant].workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${each.value.prefix}-bootstrap-${each.value.provider}"
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
