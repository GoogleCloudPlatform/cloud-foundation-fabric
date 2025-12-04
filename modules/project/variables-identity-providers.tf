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

variable "workload_identity_pools" {
  description = "Workload Identity Federation pools and providers."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    disabled     = optional(bool)
    providers = optional(map(object({
      description         = optional(string)
      display_name        = optional(string)
      attribute_condition = optional(string)
      attribute_mapping   = optional(map(string), {})
      disabled            = optional(bool, false)
      identity_provider = object({
        aws = optional(object({
          account_id = string
        }))
        oidc = optional(object({
          allowed_audiences = optional(list(string), [])
          issuer_uri        = optional(string)
          jwks_json         = optional(string)
          template          = optional(string)
        }))
        saml = optional(object({
          idp_metadata_xml = string
        }))
        # x509 = optional(object({}))
      })
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.workload_identity_pools : [
        for pk, pv in v.providers : (
          (pv.identity_provider.aws == null ? 0 : 1) +
          (pv.identity_provider.oidc == null ? 0 : 1) +
          (pv.identity_provider.saml == null ? 0 : 1)
        ) == 1
      ]
    ]))
    error_message = "Exactly one of identity_provider.aws, identity_provider.oidc, identity_provider.saml can be defined."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.workload_identity_pools : [
        for pk, pv in v.providers : contains(
          ["github", "gitlab", "okta", "terraform"],
          coalesce(try(pv.identity_provider.oidc.template, null), "github")
        )
      ]
    ]))
    error_message = "Supported provider templates are: github, gitlab, okta, terraform."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.workload_identity_pools : [
        for pk, pv in v.providers : pv.identity_provider.oidc == null || (
          pv.identity_provider.oidc.issuer_uri != null || (
            pv.identity_provider.oidc.template != null &&
            pv.identity_provider.oidc.template != "okta"
          )
        )
      ]
    ]))
    error_message = "OIDC providers need explicit issuer_uri unless template is one of github, gitlab, terraform."
  }
}
