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

variable "data_defaults" {
  description = "Optional default values used when corresponding project data from files are missing."
  type = object({
    billing_account = optional(string)
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
      project_attributes = optional(object({
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
    vpc_sc = optional(object({
      perimeter_name    = string
      perimeter_bridges = optional(list(string), [])
      is_dry_run        = optional(bool, false)
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
    vpc_sc = optional(object({
      perimeter_name    = string
      perimeter_bridges = optional(list(string), [])
      is_dry_run        = optional(bool, false)
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
    folders_data_path  = optional(string)
    projects_data_path = optional(string)
    budgets = optional(object({
      billing_account   = string
      budgets_data_path = string
      # TODO: allow defining notification channels via YAML files
      notification_channels = optional(map(any), {})
    }))
    context = optional(object({
      custom_roles          = optional(map(string), {})
      folder_ids            = optional(map(string), {})
      iam_principals        = optional(map(string), {})
      kms_keys              = optional(map(string), {})
      perimeters            = optional(map(string), {})
      tag_values            = optional(map(string), {})
      vpc_host_projects     = optional(map(string), {})
      notification_channels = optional(map(string), {})
    }), {})
    projects_config = optional(object({
      key_ignores_path = optional(bool, false)
    }), {})
  })
  nullable = false
}

variable "factories_data" {
  description = "Alternate factory data input allowing to use this module as a library. Merged with local YAML data."
  type = object({
    budgets = optional(map(object({
      amount = object({
        currency_code   = optional(string)
        nanos           = optional(number)
        units           = optional(number)
        use_last_period = optional(bool)
      })
      display_name = optional(string)
      filter = optional(object({
        credit_types_treatment = optional(object({
          exclude_all       = optional(bool)
          include_specified = optional(list(string))
        }))
        label = optional(object({
          key   = string
          value = string
        }))
        period = optional(object({
          calendar = optional(string)
          custom = optional(object({
            start_date = object({
              day   = number
              month = number
              year  = number
            })
            end_date = optional(object({
              day   = number
              month = number
              year  = number
            }))
          }))
        }))
        projects           = optional(list(string))
        resource_ancestors = optional(list(string))
        services           = optional(list(string))
        subaccounts        = optional(list(string))
      }))
      threshold_rules = optional(list(object({
        percent          = number
        forecasted_spend = optional(bool)
      })), [])
      update_rules = optional(map(object({
        disable_default_iam_recipients   = optional(bool)
        monitoring_notification_channels = optional(list(string))
        pubsub_topic                     = optional(string)
      })), {})
    })), {})
    hierarchy = optional(map(object({
      name   = optional(string)
      parent = optional(string)
      iam    = optional(map(list(string)), {})
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
      tag_bindings      = optional(map(string), {})
    })), {})
    projects = optional(map(object({
      automation = optional(object({
        project = string
        bucket = optional(object({
          location                    = string
          description                 = optional(string)
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
      vpc_sc = optional(object({
        perimeter_name    = string
        perimeter_bridges = optional(list(string), [])
        is_dry_run        = optional(bool, false)
      }))
    })), {})
  })
  nullable = false
  default  = {}
}
