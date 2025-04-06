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
  wif_outputs_stage1 = {
    for d in local._workforce_identity_providers : "${d.pool_id}.${d.provider_id}" => d
  }
}

output "identity_provider_settings" {
  description = "Collection of pertinent SAML settings to be defined in the SAML identity provider"
  value       = {
    for d in local._workforce_identity_providers : "${d.pool_id}.${d.provider_id}" => {
      saml_sso_acs_url = try(
        "https://auth.cloud.google/signin-callback/${google_iam_workforce_pool.default[d.pool_id].id}/providers/${var.prefix}-${d.provider_id}",null)
      saml_entity_id_audience = try(
        "https://iam.googleapis.com/${google_iam_workforce_pool.default[d.pool_id].id}/providers/${var.prefix}-${d.provider_id}", null)
      required_attributes = distinct([ for k, v in d.attribute_mapping : v ])
    }
  }
}