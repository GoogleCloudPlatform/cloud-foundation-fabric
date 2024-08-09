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

variable "cas_configs" {
  description = "The CAS CAs to add to each environment"
  type = object({
    dev = optional(map(object({
      ca_configs            = map(any)
      ca_pool_config        = map(any)
      location              = string
      iam                   = optional(map(list(string)), {})
      iam_bindings          = optional(map(any), {})
      iam_bindings_additive = optional(map(any), {})
      iam_by_principals     = optional(map(list(string)), {})
    })), {})
    prod = optional(map(object({
      ca_configs            = map(any)
      ca_pool_config        = map(any)
      location              = string
      iam                   = optional(map(list(string)), {})
      iam_bindings          = optional(map(any), {})
      iam_bindings_additive = optional(map(any), {})
      iam_by_principals     = optional(map(list(string)), {})
    })), {})
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name."
  type = map(object({
    rotation_period = optional(string, "7776000s")
    labels          = optional(map(string))
    locations = optional(list(string), [
      "europe", "europe-west1", "europe-west3", "global"
    ])
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
}

variable "ngfw_tls_config" {
  description = "The CAS NGFW Enterprise configuration, used for TLS Inspection."
  type = object({
    dev = optional(object({
      cas_enabled          = optional(bool, false)
      common_name          = optional(string, "dev.example.com")
      location             = optional(string, "europe-west1")
      organization         = optional(string, "Example")
      trust_config_enabled = optional(bool, false)
    }), {})
    prod = optional(object({
      cas_enabled          = optional(bool, false)
      common_name          = optional(string, "prod.example.com")
      enabled              = optional(bool, false)
      location             = optional(string, "europe-west1")
      organization         = optional(string, "Example")
      trust_config_enabled = optional(bool, false)
    }), {})
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "trust_configs" {
  description = "The trust configs grouped by environment."
  type = object({
    dev = map(object({
      description              = optional(string)
      allowlisted_certificates = optional(map(string), {})
      trust_stores = optional(map(object({
        intermediate_cas = optional(map(string), {})
        trust_anchors    = optional(map(string), {})
      })), null)
    }))
    prod = map(object({
      description              = optional(string)
      allowlisted_certificates = optional(map(string), {})
      trust_stores = optional(map(object({
        intermediate_cas = optional(map(string), {})
        trust_anchors    = optional(map(string), {})
      })), null)
    }))
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}
