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

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "security_profile_groups" {
  description = "Security profile groups for Layer 7 inspection. Null environment list means all environments."
  type = map(object({
    description  = optional(string)
    environments = optional(list(string))
    threat_prevention_profile = optional(object({
      severity_overrides = optional(map(object({
        action   = string
        severity = string
      })))
      threat_overrides = optional(map(object({
        action    = string
        threat_id = string
      })))
    }), {})
  }))
  nullable = false
  default = {
    ngfw-default = {}
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.security_profile_groups : [
        for _, sv in coalesce(v.threat_prevention_profile.severity_overrides, {}) : (
          contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], sv.action) &&
          contains(["CRITICAL", "HIGH", "INFORMATIONAL", "LOW", "MEDIUM"], sv.severity)
        )
      ]
    ]))
    error_message = "Incorrect severity override token."
  }
  validation {
    condition = alltrue(flatten([
      for _, v in var.security_profile_groups : [
        for _, sv in coalesce(v.threat_prevention_profile.threat_overrides, {}) : (
          contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], sv.action)
        )
      ]
    ]))
    error_message = "Incorrect threat override token."
  }
}

variable "trust_configs" {
  description = "Certificate Manager trust configurations for TLS inspection policies. Project id and region can reference keys in the relevant FAST variables."
  type = map(object({
    location                 = string
    project_id               = string
    description              = optional(string)
    allowlisted_certificates = optional(map(string))
    trust_stores = optional(map(object({
      intermediate_cas = optional(map(string))
      trust_anchors    = optional(map(string))
    })))
  }))
  nullable = false
  default = {
    # dev-ngfw-default = {
    #   location   = "primary"
    #   project_id = "dev-spoke-0"
    # }
    # prod-ngfw-default = {
    #   location   = "primary"
    #   project_id = "prod-spoke-0"
    # }
  }
  validation {
    condition = alltrue([
      for k, v in var.trust_configs : (
        v.allowlisted_certificates != null ||
        try(v.trust_stores.intermediate_cas, null) != null ||
        try(v.trust_stores.trust_anchors, null) != null
      )
    ])
    error_message = "a trust configuration needs at least one set of allowlisted certificates, or a valid trust store."
  }
}
