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

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    org_policies = optional(string)
  })
  nullable = false
  default  = {}
}

variable "firewall_policy" {
  description = "Hierarchical firewall policy to associate to this folder."
  type = object({
    name   = string
    policy = string
  })
  default = null
}

variable "folder_create" {
  description = "Create folder. When set to false, uses id to reference an existing folder."
  type        = bool
  default     = true
}

variable "id" {
  description = "Folder ID in case you use folder_create=false."
  type        = string
  default     = null
}

variable "logging_data_access" {
  description = "Control activation of data access logs. Format is service => { log type => [exempted members]}. The special 'allServices' key denotes configuration for all services."
  type        = map(map(list(string)))
  nullable    = false
  default     = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.logging_data_access : [
        for kk, vv in v : contains(["DATA_READ", "DATA_WRITE", "ADMIN_READ"], kk)
      ]
    ]))
    error_message = "Log type keys for each service can only be one of 'DATA_READ', 'DATA_WRITE', 'ADMIN_READ'."
  }
}

variable "logging_exclusions" {
  description = "Logging exclusions for this folder in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging_sinks" {
  description = "Logging sinks to create for the folder."
  type = map(object({
    bq_partitioned_table = optional(bool, false)
    description          = optional(string)
    destination          = string
    disabled             = optional(bool, false)
    exclusions           = optional(map(string), {})
    filter               = string
    iam                  = optional(bool, true)
    include_children     = optional(bool, true)
    type                 = string
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

variable "name" {
  description = "Folder name."
  type        = string
  default     = null
}

variable "org_policies" {
  description = "Organization policies applied to this folder keyed by policy name."
  type = map(object({
    inherit_from_parent = optional(bool) # for list policies only.
    reset               = optional(bool)
    rules = optional(list(object({
      allow = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      deny = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      enforce = optional(bool) # for boolean policies only.
      condition = optional(object({
        description = optional(string)
        expression  = optional(string)
        location    = optional(string)
        title       = optional(string)
      }), {})
    })), [])
  }))
  default  = {}
  nullable = false
}

variable "parent" {
  description = "Parent in folders/folder_id or organizations/org_id format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this folder, in key => tag value id format."
  type        = map(string)
  default     = null
}
