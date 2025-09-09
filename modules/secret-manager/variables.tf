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
    locations      = optional(map(string), {})
    tag_keys       = optional(map(string), {})
    tag_values     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "labels" {
  description = "Optional labels for each secret."
  type        = map(map(string))
  default     = {}
}

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
  description = "Map of secrets to manage, their optional expire time, version destroy ttl, locations and KMS keys in {LOCATION => KEY} format. {GLOBAL => KEY} format enables CMEK for automatic managed secrets. If locations is null, automatic management will be set."
  type = map(object({
    location_config = optional(object({
      global = optional(object({
        keys      = optional(map(string))
        locations = optional(list(string))
      }))
      regional = optional(object({
        region = string
        key    = optional(string)
      }))
    }), { global = {} })
    global_config = optional(object({
      keys      = optional(map(string))
      locations = optional(list(string))
    }), {})
    regional_config = optional(object({
      region = string
      key    = optional(string)
    }))
    expiration_config = optional(object({
      # TODO: validate only one
      time = optional(string)
      ttl  = optional(string)
    }))
    version_config = optional(object({
      aliases     = optional(map(string), {})
      destroy_ttl = optional(string)
    }), {})
    annotations         = optional(map(string), {})
    deletion_protection = optional(bool)
    labels              = optional(map(string), {})
    tag_bindings        = optional(map(string))
    tags                = optional(map(string), {})
    # rotation
    # topics
  }))
  default = {}
}

variable "versions" {
  description = "Optional versions to manage for each secret. Version names are only used internally to track individual versions."
  type = map(map(object({
    enabled = bool
    data    = string
  })))
  default = {}
}
