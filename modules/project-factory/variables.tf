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
    condition_vars        = optional(map(map(string)), {})
    custom_roles          = optional(map(string), {})
    folder_ids            = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    locations             = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids           = optional(map(string), {})
    tag_values            = optional(map(string), {})
    vpc_host_projects     = optional(map(string), {})
    vpc_sc_perimeters     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "data_defaults" {
  description = "Optional default values used when corresponding project or folder data from files are missing."
  type = object({
    billing_account = optional(string)
    bucket = optional(object({
      force_destroy = optional(bool)
    }), {})
    contacts        = optional(map(list(string)), {})
    deletion_policy = optional(string)
    factories_config = optional(object({
      custom_roles  = optional(string)
      observability = optional(string)
      org_policies  = optional(string)
      quotas        = optional(string)
    }), {})
    labels        = optional(map(string), {})
    metric_scopes = optional(list(string), [])
    parent        = optional(string)
    prefix        = optional(string)
    project_reuse = optional(object({
      use_data_source = optional(bool, true)
      attributes = optional(object({
        name             = string
        number           = number
        services_enabled = optional(list(string), [])
      }))
    }))
    service_encryption_key_ids = optional(map(list(string)), {})
    services                   = optional(list(string), [])
    shared_vpc_service_config = optional(object({
      host_project = string
      iam_bindings_additive = optional(map(object({
        member = string
        role   = string
        condition = optional(object({
          expression  = string
          title       = string
          description = optional(string)
        }))
      })), {})
      network_users            = optional(list(string), [])
      service_agent_iam        = optional(map(list(string)), {})
      service_agent_subnet_iam = optional(map(list(string)), {})
      service_iam_grants       = optional(list(string), [])
      network_subnet_users     = optional(map(list(string)), {})
    }))
    storage_location = optional(string)
    tag_bindings     = optional(map(string), {})
    # non-project resources
    service_accounts = optional(map(object({
      display_name   = optional(string, "Terraform-managed.")
      iam_self_roles = optional(list(string))
    })), {})
    universe = optional(object({
      prefix                         = string
      unavailable_service_identities = optional(list(string), [])
      unavailable_services           = optional(list(string), [])
    }))
    vpc_sc = optional(object({
      perimeter_name = string
      is_dry_run     = optional(bool, false)
    }))
    logging_data_access = optional(map(object({
      ADMIN_READ = optional(object({ exempted_members = optional(list(string)) })),
      DATA_READ  = optional(object({ exempted_members = optional(list(string)) })),
      DATA_WRITE = optional(object({ exempted_members = optional(list(string)) }))
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
    # data overrides default to null to mark that they should not override
    billing_account = optional(string)
    bucket = optional(object({
      force_destroy = optional(bool)
    }), {})
    contacts        = optional(map(list(string)))
    deletion_policy = optional(string)
    factories_config = optional(object({
      custom_roles  = optional(string)
      observability = optional(string)
      org_policies  = optional(string)
      quotas        = optional(string)
    }), {})
    parent                     = optional(string)
    prefix                     = optional(string)
    service_encryption_key_ids = optional(map(list(string)))
    storage_location           = optional(string)
    tag_bindings               = optional(map(string))
    services                   = optional(list(string))
    # non-project resources
    service_accounts = optional(map(object({
      display_name   = optional(string, "Terraform-managed.")
      iam_self_roles = optional(list(string))
    })))
    universe = optional(object({
      prefix                         = string
      unavailable_service_identities = optional(list(string), [])
      unavailable_services           = optional(list(string), [])
    }))
    vpc_sc = optional(object({
      perimeter_name = string
      is_dry_run     = optional(bool, false)
    }))
    logging_data_access = optional(map(object({
      ADMIN_READ = optional(object({ exempted_members = optional(list(string)) })),
      DATA_READ  = optional(object({ exempted_members = optional(list(string)) })),
      DATA_WRITE = optional(object({ exempted_members = optional(list(string)) }))
    })))
  })
  nullable = false
  default  = {}
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    folders           = optional(string)
    project_templates = optional(string)
    projects          = optional(string)
    budgets = optional(object({
      billing_account_id = string
      data               = string
    }))
  })
  nullable = false
}
