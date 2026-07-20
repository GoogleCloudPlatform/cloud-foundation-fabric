/**
 * Copyright 2026 Google LLC
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

variable "workforce_identity_pools" {
  description = "Workforce Identity Federation pools and providers."
  type = map(object({
    description      = optional(string)
    disabled         = optional(bool)
    display_name     = optional(string)
    session_duration = optional(string)
    access_restrictions = optional(object({
      disable_programmatic_signin = optional(bool)
      allowed_services = optional(list(object({
        domain = optional(string)
      })))
    }))
    providers = optional(map(object({
      description                = optional(string)
      display_name               = optional(string)
      attribute_condition        = optional(string)
      attribute_mapping          = optional(map(string), {})
      attribute_mapping_template = optional(string)
      disabled                   = optional(bool, false)
      detailed_audit_logging     = optional(bool, false)
      scim_usage                 = optional(string)
      identity_provider = object({
        oidc = optional(object({
          issuer_uri    = string
          client_id     = string
          client_secret = optional(string)
          jwks_json     = optional(string)
          web_sso_config = optional(object({
            # TODO: validation
            response_type             = optional(string, "CODE")
            assertion_claims_behavior = optional(string, "ONLY_ID_TOKEN_CLAIMS")
            additional_scopes         = optional(list(string))
          }))
        }))
        saml = optional(object({
          idp_metadata_xml = string
        }))
      })
      oauth2_client_config = optional(object({
        extended_attributes = optional(object({
          issuer_uri      = string
          client_id       = string
          client_secret   = string
          attributes_type = optional(string)
          query_filter    = optional(string)
        }))
        extra_attributes = optional(object({
          issuer_uri      = string
          client_id       = string
          client_secret   = string
          attributes_type = optional(string)
          query_filter    = optional(string)
        }))
      }), {})
      scim_tenant = optional(object({
        id            = string
        claim_mapping = map(string)
        location      = optional(string, "global")
        display_name  = optional(string)
        description   = optional(string)
        hard_delete   = optional(bool)
      }))
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          prov.attribute_mapping_template == null || contains(
            ["azuread", "okta"],
            prov.attribute_mapping_template
          )
        )
      ]
    ]))
    error_message = "Supported mapping templates are: azuread, okta."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          (try(prov.identity_provider.oidc, null) == null ? 0 : 1) +
          (try(prov.identity_provider.saml, null) == null ? 0 : 1)
        ) == 1
      ]
    ]))
    error_message = "Only one of identity_provider.oidc or identity_provider.saml can be defined."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          try(prov.identity_provider.oidc.web_sso_config.response_type, null) == null || contains(
            ["CODE", "ID_TOKEN"],
            try(prov.identity_provider.oidc.web_sso_config.response_type, null)
          )
        )
      ]
    ]))
    error_message = "Supported OIDC web SSO config response types are: CODE, ID_TOKEN."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          try(prov.identity_provider.oidc.web_sso_config.assertion_claims_behavior, null) == null || contains(
            ["MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS", "ONLY_ID_TOKEN_CLAIMS"],
            try(prov.identity_provider.oidc.web_sso_config.assertion_claims_behavior, null)
          )
        )
      ]
    ]))
    error_message = "Supported OIDC web SSO config assertion claims behaviors are: MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS, ONLY_ID_TOKEN_CLAIMS."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          try(prov.oauth2_client_config.extended_attributes.attributes_type, null) == null || contains(
            ["AZURE_AD_GROUPS_MAIL", "AZURE_AD_GROUPS_ID"],
            try(prov.oauth2_client_config.extended_attributes.attributes_type, null)
          )
        )
      ]
    ]))
    error_message = "Supported AzureAD attribute types in OAuth 2.0 client extended attributes are: AZURE_AD_GROUPS_MAIL, AZURE_AD_GROUPS_ID."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) : (
          try(prov.oauth2_client_config.extra_attributes.attributes_type, null) == null || contains(
            ["AZURE_AD_GROUPS_MAIL", "AZURE_AD_GROUPS_ID"],
            try(prov.oauth2_client_config.extra_attributes.attributes_type, null)
          )
        )
      ]
    ]))
    error_message = "Supported AzureAD attribute types in OAuth 2.0 client extra attributes are: AZURE_AD_GROUPS_MAIL, AZURE_AD_GROUPS_ID."
  }
  validation {
    condition = alltrue(flatten([
      for pool in values(var.workforce_identity_pools) : [
        for prov in values(pool.providers) :
        prov.scim_usage == null || prov.scim_usage == "ENABLED_FOR_GROUPS"
      ]
    ]))
    error_message = "Supported scim_usage values are: ENABLED_FOR_GROUPS."
  }
}
