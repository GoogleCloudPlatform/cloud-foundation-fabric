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
    services                   = optional(list(string), [])
    shared_vpc_service_config = optional(object({
      host_project             = string
      network_users            = optional(list(string), [])
      service_agent_iam        = optional(map(list(string)), {})
      service_agent_subnet_iam = optional(map(list(string)), {})
      service_iam_grants       = optional(list(string), [])
      network_subnet_users     = optional(map(list(string)), {})
    }), { host_project = null })
    tag_bindings = optional(map(string), {})
    # non-project resources
    service_accounts = optional(map(object({
      display_name   = optional(string, "Terraform-managed.")
      iam_self_roles = optional(list(string))
    })), {})
    vpc_sc = optional(object({
      perimeter_name    = string
      perimeter_bridges = optional(list(string), [])
      is_dry_run        = optional(bool, false)
    }))
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
    services                   = optional(list(string), [])
    tag_bindings               = optional(map(string), {})
    # non-project resources
    service_accounts = optional(map(object({
      display_name   = optional(string, "Terraform-managed.")
      iam_self_roles = optional(list(string))
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
    tag_bindings               = optional(map(string))
    services                   = optional(list(string))
    # non-project resources
    service_accounts = optional(map(object({
      display_name   = optional(string, "Terraform-managed.")
      iam_self_roles = optional(list(string))
    })))
    vpc_sc = optional(object({
      perimeter_name    = string
      perimeter_bridges = optional(list(string), [])
      is_dry_run        = optional(bool, false)
    }))
  })
  nullable = false
  default  = {}
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    folders_data_path  = optional(string)
    projects_data_path = optional(string)
    budgets = optional(object({
      billing_account   = string
      budgets_data_path = string
      # TODO: allow defining notification channels via YAML files
      notification_channels = optional(map(any), {})
    }))
    context = optional(object({
      # TODO: add KMS keys
      folder_ids        = optional(map(string), {})
      iam_principals    = optional(map(string), {})
      tag_values        = optional(map(string), {})
      vpc_host_projects = optional(map(string), {})
    }), {})
  })
  nullable = false
}
