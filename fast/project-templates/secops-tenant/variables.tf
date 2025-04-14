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

variable "secops_group_principals" {
  description = "Groups ID in IdP assigned to SecOps admins, editors, viewers roles."
  type = object({
    admins  = optional(list(string), [])
    editors = optional(list(string), [])
    viewers = optional(list(string), [])
  })
  default = {}
}

variable "secops_iam" {
  description = "SecOps IAM configuration in {PRINCIPAL => {roles => [ROLES], scopes => [SCOPES]}} format."
  type = map(object({
    roles  = list(string)
    scopes = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "secops_tenant_config" {
  description = "SecOps Tenant configuration."
  type = object({
    customer_id = string
    region      = string
  })
}

variable "secops_data_rbac_config" {
  description = "SecOps Data RBAC scope and labels config."
  type = object({
    labels = optional(map(object({
      description = string
      label_id    = string
      udm_query   = string
    })))
    scopes = optional(map(object({
      description = string
      scope_id    = string
      allowed_data_access_labels = optional(list(object({
        data_access_label = optional(string)
        log_type          = optional(string)
        asset_namespace   = optional(string)
        ingestion_label = optional(object({
          ingestion_label_key   = string
          ingestion_label_value = optional(string)
        }))
      })), [])
      denied_data_access_labels = optional(list(object({
        data_access_label = optional(string)
        log_type          = optional(string)
        asset_namespace   = optional(string)
        ingestion_label = optional(object({
          ingestion_label_key   = string
          ingestion_label_value = optional(string)
        }))
      })), [])
    })))
  })
  default = {}
}

variable "project_create_config" {
  description = "Create project instead of using an existing one."
  type = object({
    billing_account = string
    parent          = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project id that references existing project."
  type        = string
}

variable "regions" {
  description = "Region definitions."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "europe-west8"
    secondary = "europe-west1"
  }
}

variable "workspace_integration_config" {
  description = "SecOps Feeds configuration for Workspace logs and entities ingestion."
  type = object({
    workspace_customer_id = string
    delegated_user        = string
    applications = optional(list(string), ["access_transparency", "admin", "calendar", "chat", "drive", "gcp",
      "gplus", "groups", "groups_enterprise", "jamboard", "login", "meet", "mobile", "rules", "saml", "token",
      "user_accounts", "context_aware_access", "chrome", "data_studio", "keep",
    ])
  })
  default = null
}
