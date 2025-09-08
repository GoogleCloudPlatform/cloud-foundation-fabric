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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
    tag_keys       = optional(map(string), {})
    tag_values     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "iam" {
  description = "Keyring IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Keyring individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "import_job" {
  description = "Keyring import job attributes."
  type = object({
    id               = string
    import_method    = string
    protection_level = string
  })
  default = null
}

variable "keyring" {
  description = "Keyring attributes."
  type = object({
    location = string
    name     = string
  })
  nullable = false
}

variable "keyring_create" {
  description = "Set to false to manage keys and IAM bindings in an existing keyring."
  type        = bool
  default     = true
}

variable "keys" {
  description = "Key names and base attributes. Set attributes to null if not needed."
  type = map(object({
    destroy_scheduled_duration    = optional(string)
    rotation_period               = optional(string)
    labels                        = optional(map(string))
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string, "SOFTWARE")
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
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.keys : contains([
        "CRYPTO_KEY_PURPOSE_UNSPECIFIED", "ENCRYPT_DECRYPT", "ASYMMETRIC_SIGN",
        "ASYMMETRIC_DECRYPT", "RAW_ENCRYPT_DECRYPT", "MAC"
        ], v.purpose
      )
    ])
    error_message = "Invalid key purpose."
  }
  validation {
    condition = alltrue([
      for k, v in var.keys : contains([
        "SOFTWARE", "HSM", "EXTERNAL", "EXTERNAL_VPC"
      ], try(v.version_template.protection_level, "SOFTWARE"))
    ])
    error_message = "Invalid version template protection level."
  }
}

variable "project_id" {
  description = "Project id where the keyring will be created."
  type        = string
}

variable "tag_bindings" {
  description = "Tag bindings for this keyring, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}
