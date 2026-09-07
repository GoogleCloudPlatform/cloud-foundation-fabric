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

variable "adaptive_protection_config" {
  description = "Adaptive Protection configuration. Only supported by global policies."
  type = object({
    layer_7_ddos_defense = optional(object({
      enable          = optional(bool, true)
      rule_visibility = optional(string)
      threshold_configs = optional(map(object({
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
        })), [])
      })), {})
    }))
  })
  default = null
  validation {
    condition = (
      try(var.adaptive_protection_config.layer_7_ddos_defense.rule_visibility, null) == null
      || contains(
        ["STANDARD", "PREMIUM"],
        try(var.adaptive_protection_config.layer_7_ddos_defense.rule_visibility, "")
      )
    )
    error_message = "Rule visibility must be one of STANDARD or PREMIUM."
  }
}

variable "advanced_options_config" {
  description = "Advanced options configuration."
  type = object({
    json_custom_content_types    = optional(list(string))
    json_parsing                 = optional(string)
    log_level                    = optional(string)
    request_body_inspection_size = optional(string)
    user_ip_request_headers      = optional(list(string))
  })
  default = null
  validation {
    condition = (
      try(var.advanced_options_config.json_parsing, null) == null
      || contains(
        ["DISABLED", "STANDARD", "STANDARD_WITH_GRAPHQL"],
        try(var.advanced_options_config.json_parsing, "")
      )
    )
    error_message = "JSON parsing must be one of DISABLED, STANDARD, STANDARD_WITH_GRAPHQL."
  }
  validation {
    condition = (
      try(var.advanced_options_config.log_level, null) == null
      || contains(
        ["NORMAL", "VERBOSE"], try(var.advanced_options_config.log_level, "")
      )
    )
    error_message = "Log level must be one of NORMAL or VERBOSE."
  }
}

variable "ddos_protection" {
  description = "DDoS protection level. Only supported by regional policies of type CLOUD_ARMOR_NETWORK."
  type        = string
  default     = null
  validation {
    condition = (
      var.ddos_protection == null
      || contains(["STANDARD", "ADVANCED", "ADVANCED_PREVIEW"], coalesce(var.ddos_protection, "-"))
    )
    error_message = "DDoS protection must be one of STANDARD, ADVANCED, ADVANCED_PREVIEW."
  }
}

variable "default_rule_config" {
  description = "Configuration for the default rule with lowest priority, which is always present in a policy."
  type = object({
    action      = optional(string, "allow")
    description = optional(string, "Default rule.")
    preview     = optional(bool, false)
  })
  default  = {}
  nullable = false
  validation {
    condition = can(regex(
      "^(allow|deny|deny\\((403|404|502)\\))$", var.default_rule_config.action
    ))
    error_message = "Default rule action must be 'allow', 'deny', or 'deny(STATUS)' with STATUS one of 403, 404, 502."
  }
}

variable "description" {
  description = "Policy description."
  type        = string
  default     = "Terraform managed."
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    rules_file_path = optional(string)
  })
  default  = {}
  nullable = false
}

variable "labels" {
  description = "Policy labels. Only supported by global policies."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "name" {
  description = "Policy name."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "Project id where the policy will be created."
  type        = string
  nullable    = false
}

variable "recaptcha_options_config" {
  description = "reCAPTCHA configuration options. Only supported by global policies."
  type = object({
    redirect_site_key = string
  })
  default = null
}

variable "region" {
  description = "Policy region. Leave null or set to 'global' for a global policy."
  type        = string
  default     = null
}

variable "rules" {
  description = "Policy rules. Use `match` for CLOUD_ARMOR, CLOUD_ARMOR_EDGE and CLOUD_ARMOR_INTERNAL_SERVICE policies, `network_match` for CLOUD_ARMOR_NETWORK policies."
  type = map(object({
    priority    = number
    action      = string
    description = optional(string)
    preview     = optional(bool, false)
    match = optional(object({
      src_ip_ranges = optional(list(string))
      expression    = optional(string)
      recaptcha_options = optional(object({
        action_token_site_keys  = optional(list(string))
        session_token_site_keys = optional(list(string))
      }))
    }))
    network_match = optional(object({
      dest_ip_ranges      = optional(list(string))
      dest_ports          = optional(list(string))
      ip_protocols        = optional(list(string))
      src_asns            = optional(list(number))
      src_ip_ranges       = optional(list(string))
      src_ports           = optional(list(string))
      src_region_codes    = optional(list(string))
      user_defined_fields = optional(map(list(string)), {})
    }))
    header_action = optional(map(string), {})
    preconfigured_waf_config = optional(object({
      exclusions = list(object({
        target_rule_set = string
        target_rule_ids = optional(list(string))
        request_cookies = optional(list(object({
          operator = string
          value    = optional(string)
        })), [])
        request_headers = optional(list(object({
          operator = string
          value    = optional(string)
        })), [])
        request_query_params = optional(list(object({
          operator = string
          value    = optional(string)
        })), [])
        request_uris = optional(list(object({
          operator = string
          value    = optional(string)
        })), [])
      }))
    }))
    rate_limit_options = optional(object({
      exceed_action = string
      rate_limit_threshold = object({
        count        = number
        interval_sec = number
      })
      ban_duration_sec = optional(number)
      ban_threshold = optional(object({
        count        = number
        interval_sec = number
      }))
      enforce_on_key      = optional(string)
      enforce_on_key_name = optional(string)
      enforce_on_key_configs = optional(list(object({
        type = string
        name = optional(string)
      })), [])
      exceed_redirect_options = optional(object({
        type   = string
        target = optional(string)
      }))
    }))
    redirect_options = optional(object({
      type   = string
      target = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.rules : can(regex(
        "^(allow|deny|deny\\((403|404|502)\\)|throttle|rate_based_ban|redirect)$",
        v.action
      ))
    ])
    error_message = "Rule action must be one of 'allow', 'deny', 'deny(STATUS)', 'throttle', 'rate_based_ban', 'redirect'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules : v.match == null || v.network_match == null
    ])
    error_message = "Rules cannot specify both 'match' and 'network_match'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules :
      v.match == null || (
        (v.match.src_ip_ranges == null) != (v.match.expression == null)
      )
    ])
    error_message = "Rule match must specify exactly one of 'src_ip_ranges' or 'expression'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules :
      contains(["throttle", "rate_based_ban"], v.action) == (v.rate_limit_options != null)
    ])
    error_message = "Rate limit options must be set if and only if action is 'throttle' or 'rate_based_ban'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules :
      (v.action == "redirect") == (v.redirect_options != null)
    ])
    error_message = "Redirect options must be set if and only if action is 'redirect'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules :
      v.rate_limit_options == null || (
        v.rate_limit_options.enforce_on_key == null
        || length(v.rate_limit_options.enforce_on_key_configs) == 0
      )
    ])
    error_message = "Rate limit options cannot specify both 'enforce_on_key' and 'enforce_on_key_configs'."
  }
  validation {
    condition = alltrue([
      for k, v in var.rules : v.priority != 2147483647
    ])
    error_message = "Priority 2147483647 is reserved for the default rule, use the 'default_rule_config' variable instead."
  }
  validation {
    condition = (
      length(distinct([for k, v in var.rules : v.priority])) == length(var.rules)
    )
    error_message = "Rule priorities must be unique."
  }
}

variable "type" {
  description = "Policy type. Global policies support CLOUD_ARMOR, CLOUD_ARMOR_EDGE and CLOUD_ARMOR_INTERNAL_SERVICE, regional policies support CLOUD_ARMOR, CLOUD_ARMOR_EDGE and CLOUD_ARMOR_NETWORK."
  type        = string
  default     = "CLOUD_ARMOR"
  nullable    = false
  validation {
    condition = contains(
      [
        "CLOUD_ARMOR", "CLOUD_ARMOR_EDGE", "CLOUD_ARMOR_NETWORK",
        "CLOUD_ARMOR_INTERNAL_SERVICE"
      ],
      var.type
    )
    error_message = "Type must be one of CLOUD_ARMOR, CLOUD_ARMOR_EDGE, CLOUD_ARMOR_NETWORK, CLOUD_ARMOR_INTERNAL_SERVICE."
  }
}

variable "user_defined_fields" {
  description = "User-defined fields for CLOUD_ARMOR_NETWORK policies, keyed by field name."
  type = map(object({
    base   = string
    offset = optional(number)
    size   = optional(number)
    mask   = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.user_defined_fields :
      contains(["IPV4", "IPV6", "TCP", "UDP"], v.base)
    ])
    error_message = "User-defined field base must be one of IPV4, IPV6, TCP, UDP."
  }
}
