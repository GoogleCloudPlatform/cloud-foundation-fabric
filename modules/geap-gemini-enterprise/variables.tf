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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    agent_gateways        = optional(map(string), {})
    custom_roles          = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    license_configs       = optional(map(string), {})
    locations             = optional(map(string), {})
    model_armor_templates = optional(map(string), {})
    project_ids           = optional(map(string), {})
    secrets               = optional(map(string), {})
    workforce_pools       = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying created engines, data stores, schemas, CMEK configs, and data connectors (sets deletion_policy to PREVENT instead of DELETE)."
  type        = bool
  default     = true
  nullable    = false
}

variable "egress_agent_gateway" {
  description = "Optional default Egress Agent Gateway resource ID bound to apps unless overridden per app."
  type        = string
  default     = null
}

variable "encryption_config" {
  description = "Location-level CMEK configuration registered before stores and engines are created."
  type = object({
    kms_key            = string
    cmek_config_id     = optional(string, "default_cmek_config")
    set_default        = optional(bool, true)
    single_region_keys = optional(list(string), [])
  })
  default = null
}

variable "idp_config" {
  description = "Location-level Discovery Engine identity provider (ACL) configuration."
  type = object({
    idp_type            = string
    workforce_pool_name = optional(string)
  })
  default = null

  validation {
    condition = (
      var.idp_config == null
      || contains(["GSUITE", "THIRD_PARTY"], try(var.idp_config.idp_type, ""))
    )
    error_message = "idp_config.idp_type must be 'GSUITE' or 'THIRD_PARTY'."
  }

  validation {
    condition = (
      try(var.idp_config.idp_type, null) != "THIRD_PARTY"
      || try(var.idp_config.workforce_pool_name, null) != null
    )
    error_message = "idp_config.workforce_pool_name must be set when idp_type is 'THIRD_PARTY'."
  }
}

variable "location" {
  description = "Discovery Engine multi-region location (global, us, or eu)."
  type        = string
  default     = "eu"
  nullable    = false

  validation {
    condition = contains(
      ["global", "us", "eu"],
      lookup(
        var.context.locations,
        trimprefix(var.location, "$locations:"),
        var.location
      )
    )
    error_message = "location must resolve to 'global', 'us', or 'eu'."
  }
}

variable "oauth_config" {
  description = "Default OAuth 2.0 configuration for Custom MCP connectors. Can be overridden per connector via mcp_connectors[*].oauth_config."
  type = object({
    auth_uri                     = string
    client_id                    = string
    token_uri                    = string
    auth_uri_params              = optional(string)
    client_secret                = optional(string)
    client_secret_basic_override = optional(bool, true)
    pkce_support_enabled         = optional(bool, true)
    scopes                       = optional(list(string), [])
  })
  default = null

  validation {
    condition = (
      var.oauth_config == null
      ? true
      : can(regex("^https?://[^?#\\s]+$", var.oauth_config.auth_uri))
    )
    error_message = "oauth_config.auth_uri must be a valid HTTP/HTTPS URL without query parameters or fragments."
  }

  validation {
    condition = (
      try(var.oauth_config.auth_uri_params, null) == null
      ? true
      : can(regex("^(&[^&=]+=[^&]+)*$", var.oauth_config.auth_uri_params))
    )
    error_message = "oauth_config.auth_uri_params must use query parameter format: &key1=value1&key2=value2."
  }

  validation {
    condition = (
      var.oauth_config == null
      ? true
      : can(regex("^https?://.*", var.oauth_config.token_uri))
    )
    error_message = "oauth_config.token_uri must be a valid HTTP/HTTPS URL."
  }
}

variable "prefix" {
  description = "Optional prefix prepended to created engine, data store, and connector IDs."
  type        = string
  default     = null

  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project ID where Gemini Enterprise resources are managed."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "Optional project number, required when binding an Egress Agent Gateway or routing Custom MCP connectors through it."
  type        = string
  default     = null
}

variable "user_store_config" {
  description = "Location-level default_user_store license assignment configuration."
  type = object({
    default_license_config             = optional(string)
    enable_expired_license_auto_update = optional(bool)
    enable_license_auto_register       = optional(bool)
  })
  default = null
}
