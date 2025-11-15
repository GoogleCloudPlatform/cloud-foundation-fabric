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

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES."
  type        = map(list(string))
  default     = {}
  nullable    = false
  validation {
    condition = alltrue(flatten([
      for k, v in var.contacts : [
        for vv in v : contains([
          "ALL", "SUSPENSION", "SECURITY", "TECHNICAL", "BILLING", "LEGAL",
          "PRODUCT_UPDATES"
        ], vv)
      ]
    ]))
    error_message = "Invalid contact notification value."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    bigquery_datasets = optional(map(string), {})
    condition_vars    = optional(map(map(string)), {})
    custom_roles      = optional(map(string), {})
    email_addresses   = optional(map(string), {})
    iam_principals    = optional(map(string), {})
    locations         = optional(map(string), {})
    log_buckets       = optional(map(string), {})
    project_ids       = optional(map(string), {})
    pubsub_topics     = optional(map(string), {})
    storage_buckets   = optional(map(string), {})
    tag_keys          = optional(map(string), {})
    tag_values        = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    custom_roles                  = optional(string)
    org_policies                  = optional(string)
    org_policy_custom_constraints = optional(string)
    pam_entitlements              = optional(string)
    scc_sha_custom_modules        = optional(string)
    tags                          = optional(string)
  })
  nullable = false
  default  = {}
}

variable "firewall_policy" {
  description = "Hierarchical firewall policies to associate to the organization."
  type = object({
    name   = string
    policy = string
  })
  default = null
}

variable "org_policies" {
  description = "Organization policies applied to this organization keyed by policy name."
  type = map(object({
    inherit_from_parent = optional(bool) # for list policies only.
    reset               = optional(bool)
    rules = optional(list(object({
      allow = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      deny = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      enforce = optional(bool) # for boolean policies only.
      condition = optional(object({
        description = optional(string)
        expression  = optional(string)
        location    = optional(string)
        title       = optional(string)
      }), {})
      parameters = optional(string)
    })), [])
  }))
  default  = {}
  nullable = false
}

variable "org_policy_custom_constraints" {
  description = "Organization policy custom constraints keyed by constraint name."
  type = map(object({
    display_name   = optional(string)
    description    = optional(string)
    action_type    = string
    condition      = string
    method_types   = list(string)
    resource_types = list(string)
  }))
  default  = {}
  nullable = false
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
  validation {
    condition     = can(regex("^organizations/[0-9]+", var.organization_id))
    error_message = "The organization_id must in the form organizations/nnn."
  }
}

variable "workforce_identity_config" {
  description = "Workforce Identity Federation pools."
  type = object({
    pool_name = optional(string, "default")
    providers = optional(map(object({
      description                = optional(string)
      display_name               = optional(string)
      attribute_condition        = optional(string)
      attribute_mapping          = optional(map(string), {})
      attribute_mapping_template = optional(string)
      disabled                   = optional(bool, false)
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
    })), {})
  })
  nullable = true
  default  = null
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : contains(
        ["azuread", "okta"],
        coalesce(v.attribute_mapping_template, "azuread")
      )
    ])
    error_message = "Supported mapping templates are: azuread, okta."
  }
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : (
        (try(v.identity_provider.oidc, null) == null ? 0 : 1) +
        (try(v.identity_provider.saml, null) == null ? 0 : 1)
      ) == 1
    ])
    error_message = "Only one of identity_provider.oidc or identity_provider.saml can be defined."
  }
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : contains(
        ["CODE", "ID_TOKEN"],
        coalesce(try(
          v.identity_provider.oidc.web_sso_config.response_type, null
        ), "CODE")
      )
    ])
    error_message = "Invalid OIDC web SSO config response type."
  }
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : contains(
        ["MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS", "ONLY_ID_TOKEN_CLAIMS"],
        coalesce(try(
          v.identity_provider.oidc.web_sso_config.assertion_claims_behavior, null
        ), "MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS")
      )
    ])
    error_message = "Invalid OIDC web SSO config assertion claims behavior."
  }
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : contains(
        ["AZURE_AD_GROUPS_MAIL", "AZURE_AD_GROUPS_ID"],
        coalesce(try(
          v.oauth2_client_config.extended_attributes.attributes_type, null
        ), "AZURE_AD_GROUPS_MAIL")
      )
    ])
    error_message = "Invalid AzureAD attribute type in OAuth 2.0 client extended attributes.."
  }
  validation {
    condition = alltrue([
      for v in try(var.workforce_identity_config.providers, {}) : contains(
        ["AZURE_AD_GROUPS_MAIL", "AZURE_AD_GROUPS_ID"],
        coalesce(try(
          v.oauth2_client_config.extra_attributes.attributes_type, null
        ), "AZURE_AD_GROUPS_MAIL")
      )
    ])
    error_message = "Invalid AzureAD attribute type in OAuth 2.0 client extra attributes.."
  }
}
