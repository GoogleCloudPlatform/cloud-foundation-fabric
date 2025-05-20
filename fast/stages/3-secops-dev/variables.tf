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

variable "data_rbac_config" {
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

variable "factories_config" {
  description = "Paths to  YAML config expected in 'rules' and 'reference_lists'. Path to folders containing rules definitions (yaral files) and reference lists content (txt files) for the corresponding _defs keys."
  type = object({
    rules                = optional(string)
    rules_defs           = optional(string, "data/rules")
    reference_lists      = optional(string)
    reference_lists_defs = optional(string, "data/reference_lists")
  })
  nullable = false
  default = {
    rules                = "./data/secops_rules.yaml"
    rules_defs           = "./data/rules"
    reference_lists      = "./data/secops_reference_lists.yaml"
    reference_lists_defs = "./data/reference_lists"
  }
}

variable "iam" {
  description = "SecOps IAM configuration in {PRINCIPAL => {roles => [ROLES], scopes => [SCOPES]}} format."
  type = map(object({
    roles  = list(string)
    scopes = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "iam_default" {
  description = "Groups ID in IdP assigned to SecOps admins, editors, viewers roles."
  type = object({
    admins  = optional(list(string), [])
    editors = optional(list(string), [])
    viewers = optional(list(string), [])
  })
  default = {}
}

variable "project_id" {
  description = "Project id that references existing SecOps project. Use this variable when running this stage in isolation."
  type        = string
  default     = null
}

variable "project_reuse" {
  description = "Whether to use an existing project, leave default for FAST deployment."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "Google Cloud region definition for resources."
  type        = string
  default     = "europe-west8"
}

variable "stage_config" {
  description = "FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management."
  type = object({
    environment = string
    name        = string
  })
  default = {
    environment = "dev"
    name        = "secops-dev"
  }
}

variable "tenant_config" {
  description = "SecOps Tenant configuration."
  type = object({
    customer_id = string
    region      = string
  })
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
