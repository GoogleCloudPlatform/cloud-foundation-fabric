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

variable "model_armor_floor_setting" {
  description = "Model Armor floor setting for this resource. Removing it does not reset the floor setting in GCP."
  type = object({
    enforce                  = optional(bool, true)
    multi_language_detection = optional(bool)
    filters = object({
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
    })
    integrated_services = optional(object({
      ai_platform = optional(object({
        mode          = optional(string, "inspect_only")
        cloud_logging = optional(bool, false)
      }))
      google_mcp_server = optional(object({
        mode          = optional(string, "inspect_only")
        cloud_logging = optional(bool, false)
      }))
    }), {})
  })
  default = null
  validation {
    condition = alltrue([
      for v in [try(var.model_armor_floor_setting.filters, null)] : contains(
        ["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"],
        v.pi_and_jailbreak.confidence_level
      ) if try(v.pi_and_jailbreak, null) != null
    ])
    error_message = "Invalid pi_and_jailbreak confidence_level."
  }
  validation {
    condition = alltrue([
      for k, v in try(var.model_armor_floor_setting.filters.rai, {}) :
      contains(
        ["DANGEROUS", "HARASSMENT", "HATE_SPEECH", "SEXUALLY_EXPLICIT"], k
      ) && contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], v)
    ])
    error_message = "Invalid rai filter type or confidence level."
  }
  validation {
    condition = (
      try(var.model_armor_floor_setting.filters.sdp.basic, null) == null ||
      try(
        var.model_armor_floor_setting.filters.sdp.inspect_template, null
      ) == null &&
      try(
        var.model_armor_floor_setting.filters.sdp.deidentify_template, null
      ) == null
    )
    error_message = "SDP basic and template-based settings are exclusive."
  }
  validation {
    condition = alltrue([
      for k, v in try(
        var.model_armor_floor_setting.integrated_services, {}
      ) : contains(["inspect_only", "inspect_and_block"], v.mode)
      if v != null
    ])
    error_message = "Mode must be one of inspect_only, inspect_and_block."
  }
}
