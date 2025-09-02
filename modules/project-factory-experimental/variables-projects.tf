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

variable "projects" {
  description = "Projects data merged with factory data."
  type = map(object({
    automation = optional(object({
      project = string
      bucket = optional(object({
        location                    = string
        description                 = optional(string)
        force_destroy               = optional(bool)
        prefix                      = optional(string)
        storage_class               = optional(string, "STANDARD")
        uniform_bucket_level_access = optional(bool, true)
        versioning                  = optional(bool)
        iam                         = optional(map(list(string)), {})
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
        labels = optional(map(string), {})
        managed_folders = optional(map(object({
          force_destroy = optional(bool)
          iam           = optional(map(list(string)), {})
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
        })), {})
      }))
      service_accounts = optional(map(object({
        description = optional(string)
        iam         = optional(map(list(string)), {})
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
        iam_billing_roles      = optional(map(list(string)), {})
        iam_folder_roles       = optional(map(list(string)), {})
        iam_organization_roles = optional(map(list(string)), {})
        iam_project_roles      = optional(map(list(string)), {})
        iam_sa_roles           = optional(map(list(string)), {})
        iam_storage_roles      = optional(map(list(string)), {})
      })), {})
    }))
    billing_account = optional(string)
    billing_budgets = optional(list(string), [])
    buckets = optional(map(object({
      location                    = string
      description                 = optional(string)
      force_destroy               = optional(bool)
      prefix                      = optional(string)
      storage_class               = optional(string, "STANDARD")
      uniform_bucket_level_access = optional(bool, true)
      versioning                  = optional(bool)
      iam                         = optional(map(list(string)), {})
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
      labels = optional(map(string), {})
      managed_folders = optional(map(object({
        force_destroy = optional(bool)
        iam           = optional(map(list(string)), {})
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
      })), {})
    })), {})
    contacts = optional(map(list(string)), {})
    iam      = optional(map(list(string)), {})
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
    iam_by_principals = optional(map(list(string)), {})
    labels            = optional(map(string), {})
    metric_scopes     = optional(list(string), [])
    name              = optional(string)
    org_policies = optional(map(object({
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
        parameters = optional(string)
      })), [])
    })), {})
    parent = optional(string)
    prefix = optional(string)
    service_accounts = optional(map(object({
      display_name      = optional(string)
      iam_self_roles    = optional(list(string), [])
      iam_project_roles = optional(map(list(string)), {})
    })), {})
    service_encryption_key_ids = optional(map(list(string)), {})
    services                   = optional(list(string), [])
    shared_vpc_host_config = optional(object({
      enabled          = bool
      service_projects = optional(list(string), [])
    }))
    shared_vpc_service_config = optional(object({
      host_project             = string
      network_users            = optional(list(string), [])
      service_agent_iam        = optional(map(list(string)), {})
      service_agent_subnet_iam = optional(map(list(string)), {})
      service_iam_grants       = optional(list(string), [])
      network_subnet_users     = optional(map(list(string)), {})
    }))
    tag_bindings = optional(map(string), {})
    universe = optional(object({
      prefix                         = string
      unavailable_services           = optional(list(string), [])
      unavailable_service_identities = optional(list(string), [])
    }))
    vpc_sc = optional(object({
      perimeter_name = string
      is_dry_run     = optional(bool, false)
    }))
  }))
  nullable = false
  default  = {}
}
