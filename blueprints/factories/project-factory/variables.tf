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

variable "data_defaults" {
  description = "Optional default values used when corresponding project data from files are missing."
  type = object({
    billing_account            = optional(string)
    contacts                   = optional(map(list(string)), {})
    labels                     = optional(map(string), {})
    metric_scopes              = optional(list(string), [])
    parent                     = optional(string)
    prefix                     = optional(string)
    service_encryption_key_ids = optional(map(list(string)), {})
    service_perimeter_bridges  = optional(list(string), [])
    service_perimeter_standard = optional(string)
    services                   = optional(list(string), [])
    shared_vpc_service_config = optional(object({
      host_project         = string
      service_identity_iam = optional(map(list(string)), {})
      service_iam_grants   = optional(list(string), [])
    }), { host_project = null })
    tag_bindings = optional(map(string), {})
    # non-project resources
    service_accounts = optional(map(object({
      display_name      = optional(string, "Terraform-managed.")
      iam_project_roles = optional(list(string))
    })), {})
  })
  nullable = false
  default  = {}
}

variable "data_merges" {
  description = "Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`."
  type = object({
    contacts                   = optional(map(list(string)), {})
    labels                     = optional(map(string), {})
    metric_scopes              = optional(list(string), [])
    service_encryption_key_ids = optional(map(list(string)), {})
    service_perimeter_bridges  = optional(list(string), [])
    services                   = optional(list(string), [])
    tag_bindings               = optional(map(string), {})
    # non-project resources
    service_accounts = optional(map(object({
      display_name      = optional(string, "Terraform-managed.")
      iam_project_roles = optional(list(string))
    })), {})
  })
  nullable = false
  default  = {}
}

variable "data_overrides" {
  description = "Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`."
  type = object({
    billing_account            = optional(string)
    contacts                   = optional(map(list(string)))
    parent                     = optional(string)
    prefix                     = optional(string)
    service_encryption_key_ids = optional(map(list(string)))
    service_perimeter_bridges  = optional(list(string))
    service_perimeter_standard = optional(string)
    tag_bindings               = optional(map(string))
    services                   = optional(list(string))
    # non-project resources
    service_accounts = optional(map(object({
      display_name      = optional(string, "Terraform-managed.")
      iam_project_roles = optional(list(string))
    })))
  })
  nullable = false
  default  = {}
}

variable "factory_data" {
  description = "Project data from either YAML files or externally parsed data."
  type = object({
    data      = optional(map(any))
    data_path = optional(string)
  })
  nullable = false
  validation {
    condition = (
      (var.factory_data.data != null ? 1 : 0) +
      (var.factory_data.data_path != null ? 1 : 0)
    ) == 1
    error_message = "One of data or data_path needs to be set."
  }
}
