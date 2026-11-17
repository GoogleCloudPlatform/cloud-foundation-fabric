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

variable "model_armor_templates" {
  description = "Model Armor templates keyed by template id."
  type = map(object({
    location = string
    labels   = optional(map(string))
    filters = optional(object({
      malicious_uris = optional(bool)
      pi_and_jailbreak = optional(object({
        confidence_level = optional(string, "MEDIUM_AND_ABOVE")
      }))
      rai = optional(map(string), {})
      sdp = optional(object({
        basic               = optional(bool)
        inspect_template    = optional(string)
        deidentify_template = optional(string)
      }))
    }), {})
    metadata = optional(object({
      enforcement_type                   = optional(string)
      ignore_partial_invocation_failures = optional(bool)
      log_sanitize_operations            = optional(bool)
      log_template_operations            = optional(bool)
      multi_language_detection           = optional(bool)
      custom_llm_response_safety_error = optional(object({
        code    = optional(number)
        message = optional(string)
      }))
      custom_prompt_safety_error = optional(object({
        code    = optional(number)
        message = optional(string)
      }))
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.model_armor_templates : lower(v.location) != "global"
    ])
    error_message = "Templates need a regional or multi-regional location."
  }
  validation {
    condition = alltrue([
      for k, v in var.model_armor_templates : contains(
        ["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"],
        v.filters.pi_and_jailbreak.confidence_level
      ) if try(v.filters.pi_and_jailbreak, null) != null
    ])
    error_message = "Invalid pi_and_jailbreak confidence_level."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.model_armor_templates : [
        for kk, vv in v.filters.rai : contains(
          ["DANGEROUS", "HARASSMENT", "HATE_SPEECH", "SEXUALLY_EXPLICIT"], kk
        ) && contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], vv)
      ]
    ]))
    error_message = "Invalid rai filter type or confidence level."
  }
  validation {
    condition = alltrue([
      for k, v in var.model_armor_templates : (
        try(v.filters.sdp.basic, null) == null || (
          try(v.filters.sdp.inspect_template, null) == null &&
          try(v.filters.sdp.deidentify_template, null) == null
        )
      )
    ])
    error_message = "SDP basic and template-based settings are exclusive."
  }
  validation {
    condition = alltrue([
      for k, v in var.model_armor_templates : (
        try(v.filters.sdp.deidentify_template, null) == null ||
        try(v.filters.sdp.inspect_template, null) != null
      )
    ])
    error_message = "SDP deidentify_template requires inspect_template."
  }
  validation {
    condition = alltrue([
      for k, v in var.model_armor_templates : contains(
        ["INSPECT_ONLY", "INSPECT_AND_BLOCK"], v.metadata.enforcement_type
      ) if try(v.metadata.enforcement_type, null) != null
    ])
    error_message = "Invalid enforcement_type."
  }
}
