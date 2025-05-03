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

variable "auto_create_network" {
  description = "Whether to create the default network for the project."
  type        = bool
  default     = false
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "compute_metadata" {
  description = "Optional compute metadata key/values. Only usable if compute API has been enabled."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "default_service_account" {
  description = "Project default service account setting: can be one of `delete`, `deprivilege`, `disable`, or `keep`."
  default     = "keep"
  type        = string
  validation {
    condition = (
      var.default_service_account == null ||
      contains(["delete", "deprivilege", "disable", "keep"], var.default_service_account)
    )
    error_message = "Only `delete`, `deprivilege`, `disable`, or `keep` are supported."
  }
}

variable "deletion_policy" {
  description = "Deletion policy setting for this project."
  default     = "DELETE"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["ABANDON", "DELETE", "PREVENT"], var.deletion_policy)
    error_message = "deletion_policy must be one of 'ABANDON', 'DELETE', 'PREVENT'."
  }
}

variable "descriptive_name" {
  description = "Name of the project name. Used for project name instead of `name` variable."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    custom_roles  = optional(string)
    observability = optional(string)
    org_policies  = optional(string)
    quotas        = optional(string)
    context = optional(object({
      notification_channels = optional(map(string), {})
      org_policies          = optional(map(map(string)), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "lien_reason" {
  description = "If non-empty, creates a project lien with this description."
  type        = string
  default     = null
}

variable "name" {
  description = "Project name and id suffix."
  type        = string
}

variable "org_policies" {
  description = "Organization policies applied to this project keyed by policy name."
  type = map(object({
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
  }))
  default  = {}
  nullable = false
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "prefix" {
  description = "Optional prefix used to generate project id and name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_reuse" {
  description = "Reuse existing project if not null. If name and number are not passed in, a data source is used."
  type = object({
    use_data_source = optional(bool, true)
    project_attributes = optional(object({
      name             = string
      number           = number
      services_enabled = optional(list(string), [])
    }))
  })
  default = null
  validation {
    condition = (
      try(var.project_reuse.use_data_source, null) != false ||
      try(var.project_reuse.project_attributes, null) != null
    )
    error_message = "Reuse datasource can be disabled only if project attributes are set."
  }
}

variable "service_agents_config" {
  description = "Automatic service agent configuration options."
  type = object({
    create_primary_agents = optional(bool, true)
    grant_default_roles   = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "service_config" {
  description = "Configure service API activation."
  type = object({
    disable_on_destroy         = bool
    disable_dependent_services = bool
  })
  default = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
}

variable "service_encryption_key_ids" {
  description = "Service Agents to be granted encryption/decryption permissions over Cloud KMS encryption keys. Format {SERVICE_AGENT => [KEY_ID]}."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "services" {
  description = "Service APIs to enable."
  type        = list(string)
  default     = []
}

variable "shared_vpc_host_config" {
  description = "Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project)."
  type = object({
    enabled          = bool
    service_projects = optional(list(string), [])
  })
  nullable = true
  default  = null
}

variable "shared_vpc_service_config" {
  description = "Configures this project as a Shared VPC service project (mutually exclusive with shared_vpc_host_config)."
  # the list of valid service identities is in service-agents.yaml
  type = object({
    host_project             = string
    network_users            = optional(list(string), [])
    service_agent_iam        = optional(map(list(string)), {})
    service_agent_subnet_iam = optional(map(list(string)), {})
    service_iam_grants       = optional(list(string), [])
    network_subnet_users     = optional(map(list(string)), {})
  })
  default = {
    host_project = null
  }
  nullable = false
  validation {
    condition = var.shared_vpc_service_config.host_project != null || (
      var.shared_vpc_service_config.host_project == null &&
      length(var.shared_vpc_service_config.network_users) == 0 &&
      length(var.shared_vpc_service_config.service_iam_grants) == 0 &&
      length(var.shared_vpc_service_config.service_agent_iam) == 0 &&
      length(var.shared_vpc_service_config.service_agent_subnet_iam) == 0 &&
      length(var.shared_vpc_service_config.network_subnet_users) == 0
    )
    error_message = "You need to provide host_project when providing Shared VPC host and subnet IAM permissions."
  }
}

variable "skip_delete" {
  description = "Deprecated. Use deletion_policy."
  type        = bool
  default     = null
  # Validation fails on existing infrastructure. Implemented as a
  # precondition in main.tf
  # validation {
  #   condition     = var.skip_delete != null
  #   error_message = "skip_delete is deprecated. Use deletion_policy."
  # }
}

variable "universe" {
  description = "GCP universe where to deploy the project. The prefix will be prepended to the project id."
  type = object({
    prefix               = string
    unavailable_services = optional(list(string), [])
  })
  default = null
}

variable "vpc_sc" {
  description = "VPC-SC configuration for the project, use when `ignore_changes` for resources is set in the VPC-SC module."
  type = object({
    perimeter_name    = string
    perimeter_bridges = optional(list(string), [])
    is_dry_run        = optional(bool, false)
  })
  default = null
}
