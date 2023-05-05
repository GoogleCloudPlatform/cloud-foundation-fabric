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

variable "clusters" {
  description = "Map of GKE clusters to which this policy is applied in name => id format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "description" {
  description = "Policy description."
  type        = string
  default     = "Terraform managed."
}

variable "name" {
  description = "Policy name."
  type        = string
}

variable "networks" {
  description = "Map of VPC self links to which this policy is applied in name => self link format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "policy_create" {
  description = "Set to false to use the existing policy matching name and only manage rules."
  type        = bool
  default     = true
  nullable    = false
}

variable "project_id" {
  description = "Project id for the zone."
  type        = string
}

variable "rules" {
  description = "Map of policy rules in name => rule format. Local data takes precedence over behavior and is in the form record type => attributes."
  type = map(object({
    dns_name = string
    behavior = optional(string, "bypassResponsePolicy")
    local_data = optional(map(object({
      ttl     = optional(number)
      rrdatas = optional(list(string), [])
    })), {})
  }))
  default  = {}
  nullable = false
}

variable "rules_file" {
  description = "Optional data file in YAML format listing rules that will be combined with those passed in via the `rules` variable."
  type        = string
  default     = null
}
