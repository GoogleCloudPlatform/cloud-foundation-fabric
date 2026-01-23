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


variable "asset_feeds" {
  description = "Cloud Asset Inventory feeds."
  type = map(object({
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
    bigquery_datasets = optional(map(string), {})
    condition_vars    = optional(map(map(string)), {})
    custom_roles      = optional(map(string), {})
    email_addresses   = optional(map(string), {})
    iam_principals    = optional(map(string), {})
    locations         = optional(map(string), {})
    log_buckets       = optional(map(string), {})
    project_ids       = optional(map(string), {})
    pubsub_topics     = optional(map(string), {})
    storage_buckets   = optional(map(string), {})
    tag_keys          = optional(map(string), {})
    tag_values        = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    custom_roles                  = optional(string)
    org_policies                  = optional(string)
    org_policy_custom_constraints = optional(string)
    pam_entitlements              = optional(string)
    scc_sha_custom_modules        = optional(string)
    tags                          = optional(string)
  })
  nullable = false
  default  = {}
}

variable "firewall_policy" {
  description = "Hierarchical firewall policies to associate to the organization."
  type = object({
    name   = string
    policy = string
  })
  default = null
}

variable "org_policies" {
  description = "Organization policies applied to this organization keyed by policy name."
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

variable "org_policy_custom_constraints" {
  description = "Organization policy custom constraints keyed by constraint name."
  type = map(object({
    display_name   = optional(string)
    description    = optional(string)
    action_type    = string
    condition      = string
    method_types   = list(string)
    resource_types = list(string)
  }))
  default  = {}
  nullable = false
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
  validation {
    condition     = can(regex("^organizations/[0-9]+", var.organization_id))
    error_message = "The organization_id must in the form organizations/nnn."
  }
}
