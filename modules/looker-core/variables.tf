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

variable "admin_settings" {
  description = "Looker Core admins settings."
  type = object({
    allowed_email_domains = list(string)
  })
  default  = null
  nullable = true
}

variable "custom_domain" {
  description = "Looker core instance custom domain."
  type        = string
  default     = null
}

variable "encryption_config" {
  description = "Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'."
  type = object({
    kms_key_name = string
  })
  default  = null
  nullable = true
}

variable "maintenance_config" {
  description = "Set maintenance window configuration and maintenance deny period (up to 90 days). Date format: 'yyyy-mm-dd'."
  type = object({
    maintenance_window = optional(object({
      day = optional(string, "SUNDAY")
      start_time = optional(object({
        hours   = optional(number, 23)
        minutes = optional(number, 0)
        seconds = optional(number, 0)
        nanos   = optional(number, 0)
      }), {})
    }), null)
    deny_maintenance_period = optional(object({
      start_date = object({
        year  = number
        month = number
        day   = number
      })
      end_date = object({
        year  = number
        month = number
        day   = number
      })
      start_time = optional(object({
        hours   = optional(number, 23)
        minutes = optional(number, 0)
        seconds = optional(number, 0)
        nanos   = optional(number, 0)
      }), {})
    }), null)
  })
  default = {}
  validation {
    condition = (
      try(var.maintenance_config.maintenance_window, null) == null ? true : (
        var.maintenance_config.start_time.hours >= 0 &&
        var.maintenance_config.start_time.hours <= 23 &&
        var.maintenance_config.start_time.minutes == 0 &&
        var.maintenance_config.start_time.seconds == 0 &&
        var.maintenance_config.start_time.nanos == 0 &&
        # Maintenance window day validation
        contains([
          "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
        ], var.maintenance_config.day)
      )
    )
    error_message = "Maintenance window day must be between 1 and 7, maintenance window hour must be between 0 and 23 and maintenance window update_track must be 'stable' or 'canary'."
  }
}

variable "name" {
  description = "Name of the looker core instance."
  type        = string
}

variable "network_config" {
  description = "Network configuration for cluster and instance. Only one between psa_config and psc_config can be used."
  type = object({
    psa_config = optional(object({
      network            = string
      allocated_ip_range = optional(string)
      enable_public_ip   = optional(bool, false)
      enable_private_ip  = optional(bool, true)
    }))
    public = optional(bool, false)
  })
  nullable = false
  validation {
    condition     = (coalesce(var.network_config.public, false)) == (var.network_config.psa_config == null)
    error_message = "Please specify either psa_config or public to true."
  }
}

variable "oauth_config" {
  description = "Looker Core Oauth config. Either client ID and secret (existing oauth client) or support email (temporary internal oauth client setup) must be specified."
  type = object({
    client_id     = optional(string, null)
    client_secret = optional(string, null)
    support_email = optional(string, null)
  })
  validation {
    condition     = (var.oauth_config.client_id == null && var.oauth_config.client_secret == null) != (var.oauth_config.support_email == null)
    error_message = "Please specify either client_id and client_secret or support email."
  }
}

variable "platform_edition" {
  description = "Platform editions for a Looker instance. Each edition maps to a set of instance features, like its size."
  type        = string
  default     = "LOOKER_CORE_TRIAL"
  validation {
    condition     = contains(["LOOKER_CORE_TRIAL", "LOOKER_CORE_STANDARD", "LOOKER_CORE_STANDARD_ANNUAL", "LOOKER_CORE_ENTERPRISE_ANNUAL", "LOOKER_CORE_EMBED_ANNUAL"], var.platform_edition)
    error_message = "Platform Edition type must one of 'LOOKER_CORE_TRIAL', 'LOOKER_CORE_STANDARD', 'LOOKER_CORE_STANDARD_ANNUAL', 'LOOKER_CORE_ENTERPRISE_ANNUAL', 'LOOKER_CORE_EMBED_ANNUAL'."
  }
}

variable "prefix" {
  description = "Optional prefix used to generate instance names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "The ID of the project where this instances will be created."
  type        = string
}

variable "region" {
  description = "Region for the Looker core instance."
  type        = string
}
