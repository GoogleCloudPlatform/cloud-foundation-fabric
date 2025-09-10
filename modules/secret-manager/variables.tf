/**
 * Copyright 2025 Google LLC
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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
    tag_keys       = optional(map(string), {})
    tag_values     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

# variable "kms_autokey_config" {
#   description = "Key handle definitions for KMS autokey, in name => location format. Injected in the context $kms_keys:autokey/ namespace."
#   type        = map(string)
#   nullable    = false
#   default     = {}
# }

variable "project_id" {
  description = "Project id where the keyring will be created."
  type        = string
}

variable "project_number" {
  description = "Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings."
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secrets to manage. Defaults to global secrets unless region is set."
  type = map(object({
    annotations              = optional(map(string), {})
    deletion_protection      = optional(bool)
    kms_key                  = optional(string)
    labels                   = optional(map(string), {})
    global_replica_locations = optional(map(string))
    location                 = optional(string)
    tag_bindings             = optional(map(string))
    tags                     = optional(map(string), {})
    expiration_config = optional(object({
      time = optional(string)
      ttl  = optional(string)
    }))
    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    version_config = optional(object({
      aliases     = optional(map(number))
      destroy_ttl = optional(string)
    }), {})
    versions = optional(map(object({
      data            = string
      deletion_policy = optional(string)
      enabled         = optional(bool)
      data_config = optional(object({
        is_base64          = optional(bool, false)
        is_file            = optional(bool, false)
        write_only_version = optional(number)
      }))
    })), {})
    # rotation_config = optional(object({
    #   next_time = string
    #   period    = number
    # }))
    # topics
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.secrets :
      try(v.expiration_config.time, null) == null ||
      try(v.expiration_config.ttl, null) == null
    ])
    error_message = "Only one of time and ttl can be set in expiration config."
  }
  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.location == null || v.global_replica_locations == null
    ])
    error_message = "Global replication cannot be configured on regional secrets."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.secrets : [
        for sk, sv in v.versions : contains(
          ["DELETE", "DISABLE", "ABANDON"], coalesce(sv.deletion_policy, "DELETE")
        )
      ]
    ]))
    error_message = "Invalid version deletion policy."
  }
}
