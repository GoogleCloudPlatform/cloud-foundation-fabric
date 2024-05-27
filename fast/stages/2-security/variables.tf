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

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Paths to folders that enable factory functionality."
  type = object({
    vpc_sc = optional(object({
      access_levels       = optional(string, "data/vpc-sc/access-levels")
      egress_policies     = optional(string, "data/vpc-sc/egress-policies")
      ingress_policies    = optional(string, "data/vpc-sc/ingress-policies")
      restricted_services = optional(string, "data/vpc-sc/restricted-services.yaml")
    }), {})
  })
  nullable = false
  default  = {}
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

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "vpc_sc" {
  description = "VPC SC configuration."
  type = object({
    access_levels    = optional(map(any), {})
    egress_policies  = optional(map(any), {})
    ingress_policies = optional(map(any), {})
    perimeter_default = optional(object({
      access_levels    = optional(list(string), [])
      dry_run          = optional(bool, false)
      egress_policies  = optional(list(string), [])
      ingress_policies = optional(list(string), [])
      resources        = optional(list(string), [])
    }))
    resource_discovery = optional(object({
      enabled          = optional(bool, true)
      ignore_folders   = optional(list(string), [])
      ignore_projects  = optional(list(string), [])
      include_projects = optional(list(string), [])
    }), {})
  })
  default  = {}
  nullable = false
}
