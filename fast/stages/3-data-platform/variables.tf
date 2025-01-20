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

# TODO: factories for secure/policy tags, dd, dp
# TODO: refactor tag template module for template-level IAM

variable "data_domains" {
  description = ""
  type = map(object({
    # project id / resource ids use key
    # TODO: iam from project module
    # TODO: org policies from project module (check if FAST allows it)
    # TODO: check Composer3 (GA?)
    networking_config = optional(object({
      uses_local_vpc = optional(object({

      }))
      uses_shared_vpc = optional(object({

      }))
    }))
    data_products = optional(map(object{

    }), {})
  }))
}

variable "policy_tags" {
  description = ""
  type = map(object({
    region       = string
    display_name = optional(string)
    force_delete = optional(bool, false)
    fields = map(object({
      display_name = optional(string)
      description  = optional(string)
      type = object({
        primitive_type = optional(string)
        enum_type = optional(list(object({
          allowed_values = object({
            display_name = string
          })
        })), null)
      })
      is_required = optional(bool, false)
      order       = optional(number)
    }))
    iam = map(list(string))
    iam_bindings = map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    }))
    iam_bindings_additive = map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    }))
  }))
}

variable "secure_tags" {
  description = ""
  type = map(object({
    description = optional(string, "Managed by the Terraform organization module.")
    iam         = optional(map(list(string)), {})
    values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}

variable "shared_project_config" {
  description = "Configuration for the top-level shared project."
  type = object({
    # iam etc.
  })
  nullable = false
  default  = {}
}

variable "stage_config" {
  description = "FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management."
  type = object({
    environment = string
    name        = string
  })
  default = {
    environment = "dev"
    name        = "data-platform-dev"
  }
}
