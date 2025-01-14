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

variable "top_level_folders" {
  description = "Additional top-level folders. Keys are used for service account and bucket names, values implement the folders module interface with the addition of the 'automation' attribute."
  type = map(object({
    name      = string
    parent_id = optional(string)
    automation = optional(object({
      environment_name            = optional(string, "prod")
      sa_impersonation_principals = optional(list(string), [])
      short_name                  = optional(string)
    }))
    contacts = optional(map(list(string)), {})
    factories_config = optional(object({
      org_policies = optional(string)
    }))
    firewall_policy = optional(object({
      name   = string
      policy = string
    }))
    # TODO: remember to document this, and how to use the same value in other folders
    is_fast_context = optional(bool, true)
    logging_data_access = optional(map(object({
      ADMIN_READ = optional(object({ exempted_members = optional(list(string)) })),
      DATA_READ  = optional(object({ exempted_members = optional(list(string)) })),
      DATA_WRITE = optional(object({ exempted_members = optional(list(string)) }))
    })), {})
    logging_exclusions = optional(map(string), {})
    logging_settings = optional(object({
      disable_default_sink = optional(bool)
      storage_location     = optional(string)
    }))
    logging_sinks = optional(map(object({
      bq_partitioned_table = optional(bool, false)
      description          = optional(string)
      destination          = string
      disabled             = optional(bool, false)
      exclusions           = optional(map(string), {})
      filter               = optional(string)
      iam                  = optional(bool, true)
      include_children     = optional(bool, true)
      type                 = string
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
      })), [])
    })), {})
    tag_bindings = optional(map(string), {})
  }))
  nullable = false
  default  = {}
}
