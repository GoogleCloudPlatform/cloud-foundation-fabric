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
    datasets = optional(map(object({
      encryption_key = optional(string)
      friendly_name  = optional(string)
      location       = optional(string)
    })), {})
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
    iam_by_principals = optional(map(list(string)), {})
    kms = optional(object({
      autokeys = optional(map(object({
        location               = string
        resource_type_selector = string
      })), {})
      keyrings = optional(map(object({
        location = string
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
        keys = optional(map(object({
          destroy_scheduled_duration = optional(string)
          rotation_period            = optional(string)
          purpose                    = optional(string, "ENCRYPT_DECRYPT")
          iam                        = optional(map(list(string)), {})
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
          version_template = optional(object({
            algorithm        = string
            protection_level = optional(string, "SOFTWARE")
          }))
        })), {})
      })), {})
    }), {})
    labels        = optional(map(string), {})
    metric_scopes = optional(list(string), [])
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
    name = optional(string)
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
    workload_identity_pools = optional(map(object({
      display_name = optional(string)
      description  = optional(string)
      disabled     = optional(bool)
      providers = optional(map(object({
        display_name        = optional(string)
        description         = optional(string)
        attribute_condition = optional(string)
        attribute_mapping   = optional(map(string), {})
        disabled            = optional(bool, false)
        identity_provider = object({
          aws = optional(object({
            account_id = string
          }))
          oidc = optional(object({
            allowed_audiences = optional(list(string), [])
            issuer_uri        = optional(string)
            jwks_json         = optional(string)
            template          = optional(string)
          }))
          saml = optional(object({
            idp_metadata_xml = string
          }))
          # x509 = optional(object({}))
        })
      })), {})
    })), {})
  }))
  nullable = false
  default  = {}
}
