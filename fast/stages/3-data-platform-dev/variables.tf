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

# TODO: factories for secure/policy tags, dd, dp
# TODO: refactor tag template module for template-level IAM

variable "data_domains" {
  description = "Data domains defined here."
  # project id / resource ids use key
  type = map(object({
    name       = string
    short_name = optional(string)
    data_products = optional(map(object({
      short_name = optional(string)
      networking_config = optional(object({
        local_vpc_config = optional(object({
        }))
        shared_vpc_config = optional(object({
        }))
      }))
      project_config = optional(object({
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
        services          = optional(list(string))
      }), {})
      exposure_layer_config = optional(object({
        bigquery = optional(object({}))
        gcs      = optional(object({}))
      }), {})
      # project
      # - iam for dp editors
      # - services
      # - iam for consumers with condition on exposure
      # - 1-n datasets with exposure tag set
      # automation sa
    })), {})
    folder_config = optional(map(object({
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
    })))
    networking_config = optional(object({
      local_vpc_config = optional(object({
      }))
      shared_vpc_config = optional(object({
        host_project = string
      }))
    }), {})
    central_project_config = optional(object({
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
      services          = optional(list(string))
    }), {})
  }))
  nullable = false
  default  = {}
}

variable "default_region" {
  description = "Region used by default for resources when not explicitly defined. Supports interpolation from networking regions."
  type        = string
  nullable    = false
  default     = "primary"
}

variable "factories_config" {
  description = "Configuration for the resource factories."
  type = object({
    data_domains = optional(string, "data/data-domains")
    policy_tags  = optional(string, "data/policy_tags")
  })
  nullable = false
  default  = {}
}

variable "policy_tags" {
  description = "Shared data catalog tag templates."
  type = map(object({
    display_name = optional(string)
    force_delete = optional(bool, false)
    region       = optional(string)
    fields = map(object({
      display_name = optional(string)
      description  = optional(string)
      is_required  = optional(bool, false)
      order        = optional(number)
      type = object({
        primitive_type   = optional(string)
        enum_type_values = optional(list(string))
      })
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
  }))
  default = {}
}

variable "secure_tags" {
  description = "Resource manager tags created in the central project."
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
      for k, v in var.secure_tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}

variable "central_project_config" {
  description = "Configuration for the top-level central project."
  type = object({
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
    name              = optional(string)
    services = optional(list(string), [
      # TODO: define default list of services
      "datacatalog.googleapis.com",
      "logging.googleapis.com",
      "monitoring.googleapis.com"
    ])
  })
  nullable = false
  default  = {}
}

variable "stage_config" {
  description = "FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management."
  type = object({
    environment = string
    name        = string
  })
  default = {
    environment = "dev"
    name        = "data-platform-dev"
  }
}
