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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "cicd_repositories" {
  description = "CI/CD repository configuration. Identity providers reference keys in the `automation.federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed."
  type = object({
    data_platform_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    data_platform_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gke_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gke_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gcve_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gcve_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    nsec = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    networking = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    project_factory = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    project_factory_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    project_factory_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    security = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
  })
  default = null
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || try(v.name, null) != null
    ])
    error_message = "Non-null repositories need a non-null name."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || try(v.identity_provider, null) != null
    ])
    error_message = "Non-null repositories need a non-null provider."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || (
        contains(["github", "gitlab", "terraform"], coalesce(try(v.type, null), "null"))
      )
    ])
    error_message = "Invalid repository type, supported types: 'github', 'gitlab', or 'terraform'."
  }
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    checklist_data    = optional(string)
    org_policies      = optional(string, "data/org-policies")
    top_level_folders = optional(string, "data/top-level-folders")
  })
  nullable = false
  default  = {}
}

variable "fast_features" {
  description = "Selective control for top-level FAST features."
  type = object({
    data_platform = optional(bool, false)
    gke           = optional(bool, false)
    gcve          = optional(bool, false)
    nsec          = optional(bool, false)
    sandbox       = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "folder_iam" {
  description = "Authoritative IAM for top-level folders."
  type = object({
    data_platform = optional(map(list(string)), {})
    gcve          = optional(map(list(string)), {})
    gke           = optional(map(list(string)), {})
    sandbox       = optional(map(list(string)), {})
    security      = optional(map(list(string)), {})
    network       = optional(map(list(string)), {})
  })
  nullable = false
  default  = {}
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
  type        = string
  default     = null
}

variable "tag_names" {
  description = "Customized names for resource management tags."
  type = object({
    context     = optional(string, "context")
    environment = optional(string, "environment")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tags" {
  description = "Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level."
  type = map(object({
    description = optional(string, "Managed by the Terraform organization module.")
    iam         = optional(map(list(string)), {})
    values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}

variable "top_level_folders" {
  description = "Additional top-level folders. Keys are used for service account and bucket names, values implement the folders module interface with the addition of the 'automation' attribute."
  type = map(object({
    name = string
    automation = optional(object({
      enable                      = optional(bool, true)
      sa_impersonation_principals = optional(list(string), [])
    }), {})
    contacts = optional(map(list(string)), {})
    firewall_policy = optional(object({
      name   = string
      policy = string
    }))
    logging_data_access = optional(map(map(list(string))), {})
    logging_exclusions  = optional(map(string), {})
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
