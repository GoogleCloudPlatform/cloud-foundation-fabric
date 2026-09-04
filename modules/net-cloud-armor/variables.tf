# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "adaptive_protection_config" {
  description = "Adaptive Protection configuration for this security policy."
  type = object({
    layer_7_ddos_defense = optional(object({
      enable          = optional(bool, true)
      rule_visibility = optional(string, "STANDARD")
      threshold_configs = optional(list(object({
        name                                    = string
        auto_deploy_load_threshold              = optional(number)
        auto_deploy_confidence_threshold        = optional(number)
        auto_deploy_impacted_baseline_threshold = optional(number)
        auto_deploy_expiration_sec              = optional(number)
        detection_load_threshold                = optional(number)
        detection_absolute_qps                  = optional(number)
        detection_relative_to_baseline_qps      = optional(number)
        traffic_granularity_configs = optional(list(object({
          type                     = string
          value                    = optional(string)
          enable_each_unique_value = optional(bool)
        })))
      })))
    }))
  })
  default = null
}

variable "advanced_options_config" {
  description = "Advanced options configuration for this security policy."
  type = object({
    json_parsing                 = optional(string)
    log_level                    = optional(string)
    request_body_inspection_size = optional(string)
    user_ip_request_headers      = optional(list(string))
    json_custom_config = optional(object({
      content_types = list(string)
    }))
  })
  default = null
}

variable "default_rule_action" {
  description = "Action for the default rule (priority 2147483647)."
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "deny(403)", "deny(404)", "deny(502)"], var.default_rule_action)
    error_message = "Default rule action must be one of allow, deny(403), deny(404), or deny(502)."
  }
}

variable "default_rule_description" {
  description = "Description for the default rule (priority 2147483647)."
  type        = string
  default     = "Default rule."
}

variable "description" {
  description = "An optional description of this security policy."
  type        = string
  default     = "Managed by Terraform."
}

variable "factories_config" {
  description = "Paths to rule data definitions."
  type = object({
    rules_file_path = optional(string)
    rules_folder    = optional(string)
  })
  default = {}
}

variable "labels" {
  description = "Labels to apply to the security policy."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "The name of the security policy."
  type        = string
}

variable "project_id" {
  description = "The project in which the security policy belongs."
  type        = string
}

variable "recaptcha_options_config" {
  description = "reCAPTCHA configuration options for this security policy."
  type = object({
    redirect_site_key = string
  })
  default = null
}

variable "rules" {
  description = "Security policy rules."
  type = map(object({
    action            = string
    priority          = number
    description       = optional(string)
    preview           = optional(bool, false)
    preconfigured_waf = optional(string)
    threat_intel_feed = optional(string)
    # Match criteria
    src_ip_ranges = optional(list(string))
    expression    = optional(string)
    # Advanced rule options
    header_action = optional(list(object({
      header_name  = string
      header_value = string
    })))
    rate_limit_options = optional(object({
      conform_action      = optional(string, "allow")
      exceed_action       = string
      enforce_on_key      = optional(string)
      enforce_on_key_name = optional(string)
      rate_limit_threshold = object({
        count        = number
        interval_sec = number
      })
      ban_duration_sec = optional(number)
      ban_threshold = optional(object({
        count        = number
        interval_sec = number
      }))
    }))
    redirect_options = optional(object({
      type   = string
      target = optional(string)
    }))
  }))
  default = {}
}

variable "type" {
  description = "The type indicates the intended use of the security policy (CLOUD_ARMOR or CLOUD_ARMOR_EDGE)."
  type        = string
  default     = "CLOUD_ARMOR"
  validation {
    condition     = contains(["CLOUD_ARMOR", "CLOUD_ARMOR_EDGE"], var.type)
    error_message = "Type must be either CLOUD_ARMOR or CLOUD_ARMOR_EDGE."
  }
}
