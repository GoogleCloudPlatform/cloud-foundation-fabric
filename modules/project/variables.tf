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


variable "asset_feeds" {
  description = "Cloud Asset Inventory feeds."
  type = map(object({
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
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.asset_feeds :
      v.content_type == null || contains(
        ["RESOURCE", "IAM_POLICY", "ORG_POLICY", "ACCESS_POLICY", "OS_INVENTORY", "RELATIONSHIP"],
        v.content_type
      )
    ])
    error_message = "Content type must be one of RESOURCE, IAM_POLICY, ORG_POLICY, ACCESS_POLICY, OS_INVENTORY, RELATIONSHIP."
  }
}

variable "auto_create_network" {
  description = "Whether to create the default network for the project."
  type        = bool
  default     = false
}

variable "bigquery_reservations" {
  description = "BigQuery reservations and assignments. Assignment specified as {JOB_TYPE = ['projects/PROJECT_ID']}."
  type = map(object({
    location           = string
    slot_capacity      = number
    ignore_idle_slots  = optional(bool, false)
    concurrency        = optional(number)
    edition            = optional(string, "STANDARD")
    secondary_location = optional(string)
    max_slots          = optional(number)
    scaling_mode       = optional(string, "AUTOSCALE_ONLY")
    assignments        = optional(map(list(string)), {})
  }))
  validation {
    condition = alltrue([
      for name, reservation in var.bigquery_reservations :
      # Check the keys of the 'assignments' map within each reservation object.
      # If 'assignments' is omitted (defaults to {}), the inner 'alltrue' evaluates to true.
      alltrue([
        for key in keys(reservation.assignments) :
        contains(["JOB_TYPE_UNSPECIFIED",
          "PIPELINE",
          "QUERY",
          "ML_EXTERNAL",
          "BACKGROUND",
          "CONTINUOUS",
          "BACKGROUND_CHANGE_DATA_CAPTURE",
          "BACKGROUND_COLUMN_METADATA_INDEX",
        "BACKGROUND_SEARCH_INDEX_REFRESH"], key)
      ])
    ])
    error_message = "All keys in the nested 'assignments' map (within 'bigquery_reservations') must be one of the following allowed values: ML_EXTERNAL, QUERY, or BACKGROUND."
  }
  default  = {}
  nullable = false
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
  validation {
    condition = alltrue(flatten([
      for k, v in var.contacts : [
        for vv in v : contains([
          "ALL", "SUSPENSION", "SECURITY", "TECHNICAL", "BILLING", "LEGAL",
          "PRODUCT_UPDATES"
        ], vv)
      ]
    ]))
    error_message = "Invalid contact notification value."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    bigquery_datasets     = optional(map(string), {})
    condition_vars        = optional(map(map(string)), {})
    custom_roles          = optional(map(string), {})
    email_addresses       = optional(map(string), {})
    folder_ids            = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    log_buckets           = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids           = optional(map(string), {})
    pubsub_topics         = optional(map(string), {})
    storage_buckets       = optional(map(string), {})
    tag_keys              = optional(map(string), {})
    tag_values            = optional(map(string), {})
    vpc_sc_perimeters     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "default_network_tier" {
  description = "Default compute network tier for the project."
  type        = string
  default     = null
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
  description = "Descriptive project name. Set when name differs from project id."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    custom_roles           = optional(string)
    observability          = optional(string)
    org_policies           = optional(string)
    pam_entitlements       = optional(string)
    quotas                 = optional(string)
    scc_sha_custom_modules = optional(string)
    tags                   = optional(string)
  })
  nullable = false
  default  = {}
}

variable "kms_autokeys" {
  description = "KMS Autokey key handles."
  type = map(object({
    location               = string
    resource_type_selector = optional(string, "compute.googleapis.com/Disk")
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.kms_autokeys : k == try(regex(
        "^[a-z][a-z0-9-]+[a-z0-9]$", k
      ), null)
    ])
    error_message = "Autokey keys need to be valid GCP resource names."
  }
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
    condition = (
      var.parent == null ||
      startswith(coalesce(var.parent, "-"), "$") ||
      can(regex("(organizations|folders)/[0-9]+", coalesce(var.parent, "-")))
    )
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id or refer to a context variable via the '$' prefix."
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
    attributes = optional(object({
      name             = string
      number           = number
      services_enabled = optional(list(string), [])
    }))
  })
  default = null
  validation {
    condition = (
      try(var.project_reuse.use_data_source, null) != false ||
      try(var.project_reuse.attributes, null) != null
    )
    error_message = "Reuse datasource can be disabled only if attributes are set."
  }
}

variable "service_agents_config" {
  description = "Automatic service agent configuration options."
  type = object({
    create_primary_agents      = optional(bool, true)
    grant_default_roles        = optional(bool, true)
    grant_service_agent_editor = optional(bool, true)
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
    prefix                         = string
    forced_jit_service_identities  = optional(list(string), [])
    unavailable_services           = optional(list(string), [])
    unavailable_service_identities = optional(list(string), [])
  })
  default = null
}

variable "vpc_sc" {
  description = "VPC-SC configuration for the project, use when `ignore_changes` for resources is set in the VPC-SC module."
  type = object({
    perimeter_name = string
    is_dry_run     = optional(bool, false)
  })
  default = null
}
