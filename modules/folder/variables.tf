/**
 * Copyright 2023 Google LLC
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

variable "assured_workload_config" {
  description = "Create AssuredWorkloads folder instead of regular folder when value is provided. Incompatible with folder_create=false."
  type = object({
    compliance_regime         = string
    display_name              = string
    location                  = string
    organization              = string
    enable_sovereign_controls = optional(bool)
    labels                    = optional(map(string), {})
    partner                   = optional(string)
    partner_permissions = optional(object({
      assured_workloads_monitoring = optional(bool)
      data_logs_viewer             = optional(bool)
      service_access_approver      = optional(bool)
    }))
    violation_notifications_enabled = optional(bool)

  })
  default = null
  validation {
    condition = try(contains([
      "ASSURED_WORKLOADS_FOR_PARTNERS",
      "AU_REGIONS_AND_US_SUPPORT",
      "CA_PROTECTED_B, IL5",
      "CA_REGIONS_AND_SUPPORT",
      "CJIS",
      "COMPLIANCE_REGIME_UNSPECIFIED",
      "EU_REGIONS_AND_SUPPORT",
      "FEDRAMP_HIGH",
      "FEDRAMP_MODERATE",
      "HIPAA, HITRUST",
      "IL2",
      "IL4",
      "ISR_REGIONS_AND_SUPPORT",
      "ISR_REGIONS",
      "ITAR",
      "JP_REGIONS_AND_SUPPORT",
      "US_REGIONAL_ACCESS"
    ], var.assured_workload_config.compliance_regime), true)
    error_message = "Field assured_workload_config.compliance_regime must be one of the values listed in https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/ComplianceRegime"
  }
  validation {
    condition = try(contains([
      "LOCAL_CONTROLS_BY_S3NS",
      "PARTNER_UNSPECIFIED",
      "SOVEREIGN_CONTROLS_BY_PSN",
      "SOVEREIGN_CONTROLS_BY_SIA_MINSAIT",
      "SOVEREIGN_CONTROLS_BY_T_SYSTEMS"
    ], var.assured_workload_config.partner), true)
    error_message = "Field assured_workload_config.partner must be one of the values listed in https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/Partner"
  }
}

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "deletion_protection" {
  description = "Deletion protection setting for this folder."
  type        = bool
  default     = false
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    org_policies = optional(string)
  })
  nullable = false
  default  = {}
}

variable "firewall_policy" {
  description = "Hierarchical firewall policy to associate to this folder."
  type = object({
    name   = string
    policy = string
  })
  default = null
}

variable "folder_create" {
  description = "Create folder. When set to false, uses id to reference an existing folder."
  type        = bool
  default     = true
}

variable "id" {
  description = "Folder ID in case you use folder_create=false."
  type        = string
  default     = null
}

variable "name" {
  description = "Folder name."
  type        = string
  default     = null
}

variable "org_policies" {
  description = "Organization policies applied to this folder keyed by policy name."
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
    })), [])
  }))
  default  = {}
  nullable = false
}

variable "parent" {
  description = "Parent in folders/folder_id or organizations/org_id format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this folder, in key => tag value id format."
  type        = map(string)
  default     = null
}
