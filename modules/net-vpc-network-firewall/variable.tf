/**
 * Copyright 2022 Google LLC
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

variable "data_folders" {
  description = "List of paths to folders where firewall configs are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml`."
  type        = list(string)
  default     = null
}

variable "deployment_scope" {
  description = ""
  type        = string
  validation {
    condition = contains(
      ["global", "regional"],
      var.deployment_scope
    )
    error_message = "Invalid deployment scope, supported scope: 'global' or 'regional'."
  }
}

variable "firewall_policy_region" {
  description = "Network firewall policy region."
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "List rule definitions, default to allow action."
  type = map(object({
    action         = optional(string, "allow")
    description    = optional(string, null)
    dest_ip_ranges = optional(list(string))
    disabled       = optional(bool, false)
    direction      = optional(string, "INGRESS")
    enable_logging = optional(bool, false)
    layer4_configs = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [{ protocol = "all" }])
    priority                = optional(number, 1000)
    src_secure_tags         = optional(list(string))
    src_ip_ranges           = optional(list(string))
    target_service_accounts = optional(list(string))
    target_secure_tags      = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "global_network" {
  description = "VPC SelfLink to attach the global firewall policy."
  type        = string
  default     = null
}
variable "global_policy_name" {
  description = "Global network firewall policy name."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  type        = string
}

variable "regional_network" {
  description = "VPC SelfLink to attach the regional firewall policy."
  type        = string
  default     = null
}
variable "regional_policy_name" {
  description = "Global network firewall policy name."
  type        = string
  default     = null
}