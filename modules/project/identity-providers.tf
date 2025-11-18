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
  wif_providers = merge([
    for k, v in var.workload_identity_pools : {
      for pk, pv in v.providers : "${k}/${pk}" => merge(pv, {
        provider_id = pk
        pool        = k
        attribute_mapping = merge(
          try(
            local.wif_defs[pv.identity_provider.oidc.template].attribute_mapping, {}
          ),
          pv.attribute_mapping
        )
      })
    }
  ]...)
}

resource "google_iam_workload_identity_pool" "default" {
  for_each                  = var.workload_identity_pools
  project                   = local.project.project_id
  workload_identity_pool_id = each.key
  display_name              = each.value.display_name
  description               = each.value.description
  disabled                  = each.value.disabled
}

resource "google_iam_workload_identity_pool_provider" "default" {
  for_each = local.wif_providers
  project  = local.project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default[each.value.pool].workload_identity_pool_id
  )
  workload_identity_pool_provider_id = each.value.provider_id
  attribute_condition                = each.value.attribute_condition
  attribute_mapping                  = each.value.attribute_mapping
  description                        = each.value.description
  display_name                       = each.value.display_name
  disabled                           = each.value.disabled
  dynamic "aws" {
    for_each = each.value.identity_provider.aws == null ? [] : [""]
    content {
      account_id = each.value.identity_provider.aws.account_id
    }
  }
  dynamic "oidc" {
    for_each = each.value.identity_provider.oidc == null ? [] : [""]
    content {
      # don't fail in the coalesce for a null issuer, but let the API do it
      issuer_uri = coalesce(
        # if a specific issuer is set, it overrides the template
        each.value.identity_provider.oidc.issuer_uri,
        try(
          local.wif_defs[each.value.identity_provider.oidc.template].issuer_uri,
          null
        )
      )
      allowed_audiences = each.value.identity_provider.oidc.allowed_audiences
      jwks_json         = each.value.identity_provider.oidc.jwks_json
    }
  }
  dynamic "saml" {
    for_each = each.value.identity_provider.saml == null ? [] : [""]
    content {
      idp_metadata_xml = each.value.identity_provider.saml.idp_metadata_xml
    }
  }
}

