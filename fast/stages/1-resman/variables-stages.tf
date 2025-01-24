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

variable "fast_stage_2" {
  description = "FAST stages 2 configurations."
  type = map(object({
    short_name = optional(string)
    cicd_config = optional(object({
      identity_provider = string
      repository = object({
        name   = string
        branch = optional(string)
        type   = optional(string, "github")
      })
    }))
    folder_config = optional(object({
      name               = string
      parent_id          = optional(string)
      create_env_folders = optional(bool, true)
      iam                = optional(map(list(string)), {})
      iam_bindings       = optional(map(list(string)), {})
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
    }))
    organization_config = optional(object({
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
    }), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.fast_stage_2 :
      v.cicd_config == null || contains(
        ["github", "gitlab"],
        coalesce(try(v.cicd_config.repository.type, null), "-")
      )
    ])
    error_message = "Invalid CI/CD repository type."
  }
}

variable "fast_stage_3" {
  description = "FAST stages 3 configurations."
  # key is used for file names and loop keys and is like 'data-platfom-dev'
  type = map(object({
    short_name  = optional(string)
    environment = optional(string, "dev")
    cicd_config = optional(object({
      identity_provider = string
      repository = object({
        name   = string
        branch = optional(string)
        type   = optional(string, "github")
      })
    }))
    folder_config = optional(object({
      name         = string
      parent_id    = optional(string)
      tag_bindings = optional(map(string), {})
      iam          = optional(map(list(string)), {})
      iam_bindings = optional(map(list(string)), {})
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
    }))
  }))
  nullable = false
  default  = {}
  # TODO: upgrade to cross-variable validation
  validation {
    condition = alltrue([
      for k, v in var.fast_stage_3 :
      contains(["dev", "prod"], coalesce(v.environment, "-"))
    ])
    error_message = "Invalid environment value."
  }
  validation {
    condition = alltrue([
      for k, v in var.fast_stage_3 :
      v.cicd_config == null || contains(
        ["github", "gitlab"],
        coalesce(try(v.cicd_config.repository.type, null), "-")
      )
    ])
    error_message = "Invalid CI/CD repository type."
  }
}
