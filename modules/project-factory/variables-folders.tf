/**
 * Copyright 2026 Google LLC
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

variable "folders" {
  description = "Folders data merged with factory data."
  type = map(object({
    asset_search = optional(map(object({
      asset_types = list(string)
      query       = optional(string)
    })), {})
    asset_feeds = optional(map(object({
      billing_project = string
      content_type    = optional(string)
      asset_types     = optional(list(string))
      asset_names     = optional(list(string))
      feed_output_config = object({
        pubsub_destination = object({
          topic = string
        })
      })
      condition = optional(object({
        expression  = string
        title       = optional(string)
        description = optional(string)
        location    = optional(string)
      }))
    })), {})
    assured_workload_config = optional(object({
      compliance_regime         = string
      display_name              = string
      location                  = string
      organization              = string
      enable_sovereign_controls = optional(bool)
      labels                    = optional(map(string), {})
      partner                   = optional(string)
      partner_permissions = optional(object({
        assured_workloads_monitoring = optional(bool)
        data_logs_viewer             = optional(bool)
        service_access_approver      = optional(bool)
      }))
      violation_notifications_enabled = optional(bool)
    }), null)
    automation = optional(object({
      project = string
      prefix  = optional(string)
      bucket = optional(object({
        location                    = optional(string)
        create                      = optional(bool, true)
        encryption_key              = optional(string)
        force_destroy               = optional(bool)
        name                        = optional(string, "tf-state")
        prefix                      = optional(string)
        public_access_prevention    = optional(string)
        storage_class               = optional(string, "STANDARD")
        uniform_bucket_level_access = optional(bool, true)
        versioning                  = optional(bool, false)
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
        lifecycle_rules = optional(map(object({
          action = object({
            type          = string
            storage_class = optional(string)
          })
          condition = object({
            age                        = optional(number)
            created_before             = optional(string)
            custom_time_before         = optional(string)
            days_since_custom_time     = optional(number)
            days_since_noncurrent_time = optional(number)
            matches_prefix             = optional(list(string))
            matches_storage_class      = optional(list(string))
            matches_suffix             = optional(list(string))
            noncurrent_time_before     = optional(string)
            num_newer_versions         = optional(number)
            with_state                 = optional(string)
          })
        })), {})
        logging_config = optional(object({
          log_bucket        = string
          log_object_prefix = optional(string)
        }), null)
        retention_policy = optional(object({
          retention_period = string
          is_locked        = optional(bool)
        }))
        soft_delete_retention = optional(number)
      }))
      service_accounts = optional(map(object({
        description  = optional(string)
        display_name = optional(string)
        prefix       = optional(string)
        iam          = optional(map(list(string)), {})
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
        iam_billing_bindings = optional(map(object({
          billing_account_id = string
          role               = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_billing_roles = optional(map(list(string)), {})
        iam_folder_bindings = optional(map(object({
          folder_id = string
          role      = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_folder_roles = optional(map(list(string)), {})
        iam_organization_bindings = optional(map(object({
          organization_id = string
          role            = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_organization_roles = optional(map(list(string)), {})
        iam_project_bindings = optional(map(object({
          project_id = string
          role       = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_project_roles = optional(map(list(string)), {})
        iam_sa_bindings = optional(map(object({
          service_account_id = string
          role               = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_sa_roles = optional(map(list(string)), {})
        iam_storage_bindings = optional(map(object({
          bucket = string
          role   = string
          condition = optional(object({
            expression  = string
            title       = string
            description = optional(string)
          }))
        })), {})
        iam_storage_roles = optional(map(list(string)), {})
        tag_bindings      = optional(map(string), {})
      })), {})
    }))
    cloud_armor_policy = optional(object({
      name              = optional(string)
      policy_id         = string
      excluded_folders  = optional(list(string), [])
      excluded_projects = optional(list(string), [])
    }))
    contacts            = optional(map(list(string)), {})
    id                  = optional(string)
    name                = optional(string)
    parent              = optional(string)
    deletion_protection = optional(bool, false)
    firewall_policy = optional(object({
      name   = string
      policy = string
    }))
    logging = optional(object({
      kms_key_name     = optional(string)
      storage_location = optional(string)
      sinks = optional(map(object({
        description        = optional(string)
        destination        = string
        disabled           = optional(bool, false)
        exclusions         = optional(map(string), {})
        filter             = optional(string)
        iam                = optional(bool, true)
        include_children   = optional(bool, true)
        intercept_children = optional(bool, false)
        type               = optional(string, "logging")
      })), {})
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
    iam_by_principals          = optional(map(list(string)), {})
    iam_by_principals_additive = optional(map(list(string)), {})
    iam_by_principals_conditional = optional(map(object({
      roles = list(string)
      condition = object({
        expression  = string
        title       = string
        description = optional(string)
      })
    })), {})
    org_policies = optional(map(object({
      inherit_from_parent = optional(bool)
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
        enforce = optional(bool)
        condition = optional(object({
          description = optional(string)
          expression  = optional(string)
          location    = optional(string)
          title       = optional(string)
        }), {})
        parameters = optional(string)
      })), [])
    })), {})
    pam_entitlements = optional(map(object({
      max_request_duration = string
      eligible_users       = list(string)
      privileged_access = list(object({
        role      = string
        condition = optional(string)
      }))
      requester_justification_config = optional(object({
        not_mandatory = optional(bool, true)
        unstructured  = optional(bool, false)
      }), { not_mandatory = false, unstructured = true })
      manual_approvals = optional(object({
        require_approver_justification = bool
        steps = list(object({
          approvers                 = list(string)
          approvals_needed          = optional(number, 1)
          approver_email_recipients = optional(list(string))
        }))
      }))
      additional_notification_targets = optional(object({
        admin_email_recipients     = optional(list(string))
        requester_email_recipients = optional(list(string))
      }))
    })), {})
    tag_bindings = optional(map(string), {})
  }))
  nullable = false
  default  = {}
}
