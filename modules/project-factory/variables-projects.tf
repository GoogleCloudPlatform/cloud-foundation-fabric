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

variable "projects" {
  description = "Projects data merged with factory data."
  type = map(object({
    asset_feeds = optional(map(object({
      billing_project = optional(string)
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
    iam_by_principals_conditional = optional(map(object({
      roles = list(string)
      condition = object({
        expression  = string
        title       = string
        description = optional(string)
      })
    })), {})
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
    name             = optional(string)
    descriptive_name = optional(string)
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
    pubsub_topics = optional(map(object({
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
      kms_key                    = optional(string)
      labels                     = optional(map(string), {})
      message_retention_duration = optional(string)
      regions                    = optional(list(string), [])
      schema = optional(object({
        definition   = string
        msg_encoding = optional(string, "ENCODING_UNSPECIFIED")
        schema_type  = string
      }))
      subscriptions = optional(map(object({
        ack_deadline_seconds         = optional(number)
        enable_exactly_once_delivery = optional(bool, false)
        enable_message_ordering      = optional(bool, false)
        expiration_policy_ttl        = optional(string)
        filter                       = optional(string)
        iam                          = optional(map(list(string)), {})
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
        labels                     = optional(map(string))
        message_retention_duration = optional(string)
        retain_acked_messages      = optional(bool, false)
        bigquery = optional(object({
          table                 = string
          drop_unknown_fields   = optional(bool, false)
          service_account_email = optional(string)
          use_table_schema      = optional(bool, false)
          use_topic_schema      = optional(bool, false)
          write_metadata        = optional(bool, false)
        }))
        cloud_storage = optional(object({
          bucket          = string
          filename_prefix = optional(string)
          filename_suffix = optional(string)
          max_duration    = optional(string)
          max_bytes       = optional(number)
          avro_config = optional(object({
            write_metadata = optional(bool, false)
          }))
        }))
        dead_letter_policy = optional(object({
          topic                 = string
          max_delivery_attempts = optional(number)
        }))
        push = optional(object({
          endpoint   = string
          attributes = optional(map(string))
          no_wrapper = optional(object({
            write_metadata = optional(bool, false)
          }))
          oidc_token = optional(object({
            audience              = optional(string)
            service_account_email = string
          }))
        }))
        retry_policy = optional(object({
          minimum_backoff = optional(number)
          maximum_backoff = optional(number)
        }))
      })), {})
    })), {})
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
