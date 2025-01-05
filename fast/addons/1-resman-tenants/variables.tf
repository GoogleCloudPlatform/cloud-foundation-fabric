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

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "root_node" {
  description = "Root folder under which tenants are created, in folders/nnnn format. Defaults to the organization if null."
  type        = string
  default     = null
  validation {
    condition = (
      var.root_node == null ||
      startswith(coalesce(var.root_node, "-"), "folders/")
    )
    error_message = "Root node must be a folder in folders/nnnn format."
  }
}

variable "tag_names" {
  description = "Customized names for resource management tags."
  type = object({
    tenant = optional(string, "tenant")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tenant_configs" {
  description = "Tenant configurations. Keys are the short names used for naming resources and should not be changed once defined."
  type = map(object({
    admin_principal  = string
    descriptive_name = string
    billing_account = optional(object({
      id = optional(string)
      # is_org_level is only meaningful when using the org BA
      # and set implicitly in tenant locals
      no_iam = optional(bool, true)
    }), {})
    cloud_identity = optional(object({
      customer_id = string
      domain      = string
      id          = string
    }))
    locations = optional(object({
      bq      = optional(string, "EU")
      gcs     = optional(string, "EU")
      logging = optional(string, "global")
      pubsub  = optional(list(string), [])
    }))
    fast_config = optional(object({
      cicd_config = optional(object({
        name              = string
        type              = string
        branch            = optional(string)
        identity_provider = optional(string)
      }))
      groups = optional(object({
        gcp-billing-admins      = optional(string, "gcp-billing-admins")
        gcp-devops              = optional(string, "gcp-devops")
        gcp-network-admins      = optional(string, "gcp-vpc-network-admins")
        gcp-organization-admins = optional(string, "gcp-organization-admins")
        gcp-security-admins     = optional(string, "gcp-security-admins")
        gcp-support             = optional(string, "gcp-devops")
      }))
      prefix = optional(string)
      workload_identity_providers = optional(map(object({
        attribute_condition = optional(string)
        issuer              = string
        custom_settings = optional(object({
          issuer_uri = optional(string)
          audiences  = optional(list(string), [])
          jwks_json  = optional(string)
        }), {})
      })), {})
    }))
    vpc_sc_policy_create = optional(bool, false)
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tenant_configs :
      length(coalesce(try(v.fast_config.prefix, null), "-")) < 11
    ])
    error_message = "Tenant prefix too long, use a maximum of 10 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.tenant_configs : length(k) <= 3
    ])
    error_message = "Tenant short name too long, use a maximum of 3 characters."
  }
}
