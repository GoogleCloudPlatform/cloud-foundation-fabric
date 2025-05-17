/**
 * Copyright 2023 Google LLC
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

variable "factories_config" {
  description = "Paths to  YAML config expected in 'rules' and 'reference_lists'. Path to folders containing rules definitions (yaral files) and reference lists content (txt files) for the corresponding _defs keys."
  type = object({
    rules                = optional(string)
    rules_defs           = optional(string, "data/rules")
    reference_lists      = optional(string)
    reference_lists_defs = optional(string, "data/reference_lists")
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "Project used for resources."
  type        = string
}

variable "reference_lists_config" {
  description = "SecOps Reference lists configuration."
  type = map(object({
    description = string
    type        = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for config in var.reference_lists_config : contains(["CIDR", "STRING", "REGEX"], config.type)
    ])
    error_message = "The 'type' attribute for each reference list must be one of: CIDR, STRING, REGEX."
  }
}

variable "rules_config" {
  description = "SecOps Detection rules configuration."
  type = map(object({
    enabled  = optional(bool, true)
    alerting = optional(bool, false)
    archived = optional(bool, false)
    run_frequency : optional(string)
  }))
  default = {}
  validation {
    condition = alltrue([
      for config in var.rules_config : contains(["LIVE", "HOURLY", "DAILY"], config.run_frequency)
    ])
    error_message = "The 'type' attribute for each reference list must be one of: CIDR, STRING, REGEX."
  }
}

variable "tenant_config" {
  description = "SecOps Tenant configuration."
  type = object({
    customer_id = string
    region      = string
  })
}
