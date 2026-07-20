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

variable "asset_search" {
  description = "Cloud Asset Inventory search configurations."
  type = map(object({
    asset_types = list(string)
    query       = optional(string)
  }))
  default  = {}
  nullable = false
}

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
      "AUSTRALIA_DATA_BOUNDARY_AND_SUPPORT",
      "CA_PROTECTED_B",
      "CA_REGIONS_AND_SUPPORT",
      "CANADA_CONTROLLED_GOODS",
      "CANADA_DATA_BOUNDARY_AND_SUPPORT",
      "CJIS",
      "COMPLIANCE_REGIME_UNSPECIFIED",
      "DATA_BOUNDARY_FOR_CANADA_CONTROLLED_GOODS",
      "DATA_BOUNDARY_FOR_CANADA_PROTECTED_B",
      "DATA_BOUNDARY_FOR_CJIS",
      "DATA_BOUNDARY_FOR_FEDRAMP_HIGH",
      "DATA_BOUNDARY_FOR_FEDRAMP_MODERATE",
      "DATA_BOUNDARY_FOR_IL2",
      "DATA_BOUNDARY_FOR_IL4",
      "DATA_BOUNDARY_FOR_IL5",
      "DATA_BOUNDARY_FOR_IRS_PUBLICATION_1075",
      "DATA_BOUNDARY_FOR_ITAR",
      "EU_DATA_BOUNDARY_AND_SUPPORT",
      "EU_REGIONS_AND_SUPPORT",
      "FEDRAMP_HIGH",
      "FEDRAMP_MODERATE",
      "HEALTHCARE_AND_LIFE_SCIENCES_CONTROLS",
      "HEALTHCARE_AND_LIFE_SCIENCES_CONTROLS_US_SUPPORT",
      "HIPAA",   # DEPRECATED
      "HITRUST", # DEPRECATED
      "IL2",
      "IL4",
      "IL5",
      "IRS_1075",
      "ISR_REGIONS",
      "ISR_REGIONS_AND_SUPPORT",
      "ISRAEL_DATA_BOUNDARY_AND_SUPPORT",
      "ITAR",
      "JAPAN_DATA_BOUNDARY",
      "JP_REGIONS_AND_SUPPORT",
      "KSA_DATA_BOUNDARY_WITH_ACCESS_JUSTIFICATIONS",
      "KSA_REGIONS_AND_SUPPORT_WITH_SOVEREIGNTY_CONTROLS",
      "REGIONAL_CONTROLS",
      "REGIONAL_DATA_BOUNDARY",
      "US_DATA_BOUNDARY_AND_SUPPORT",
      "US_DATA_BOUNDARY_FOR_HEALTHCARE_AND_LIFE_SCIENCES",
      "US_DATA_BOUNDARY_FOR_HEALTHCARE_AND_LIFE_SCIENCES_WITH_SUPPORT",
      "US_REGIONAL_ACCESS"
    ], var.assured_workload_config.compliance_regime), true)
    error_message = "Field assured_workload_config.compliance_regime must be one of the values listed in https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/ComplianceRegime"
  }
  validation {
    condition = try(contains([
      "LOCAL_CONTROLS_BY_S3NS",
      "PARTNER_UNSPECIFIED",
      "SOVEREIGN_CONTROLS_BY_CNTXT_NO_EKM",
      "SOVEREIGN_CONTROLS_BY_CNTXT",
      "SOVEREIGN_CONTROLS_BY_PSN",
      "SOVEREIGN_CONTROLS_BY_SIA_MINSAIT",
      "SOVEREIGN_CONTROLS_BY_T_SYSTEMS",
    ], var.assured_workload_config.partner), true)
    error_message = "Field assured_workload_config.partner must be one of the values listed in https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/Partner"
  }
}

variable "autokey_config" {
  description = "Enable autokey support for this folder's children. Project accepts either project id or number."
  type = object({
    project = string
  })
  nullable = true
  default  = null
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
    folder_ids        = optional(map(string), {})
    iam_principals    = optional(map(string), {})
    kms_keys          = optional(map(string), {})
    log_buckets       = optional(map(string), {})
    project_ids       = optional(map(string), {})
    project_numbers   = optional(map(string), {})
    pubsub_topics     = optional(map(string), {})
    storage_buckets   = optional(map(string), {})
    tag_values        = optional(map(string), {})
    tag_vars = optional(object({
      projects     = optional(map(map(string)), {})
      organization = optional(map(string), {})
    }), {})
  })
  default  = {}
  nullable = false
}

variable "deletion_protection" {
  description = "Deletion protection setting for this folder."
  type        = bool
  default     = false
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    org_policies           = optional(string)
    pam_entitlements       = optional(string)
    scc_mute_configs       = optional(string)
    scc_sha_custom_modules = optional(string)
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

# keep the following variable as it allows passing in a dynamic value for id

variable "folder_create" {
  description = "Create folder. When set to false, uses id to reference an existing folder."
  type        = bool
  default     = true
  validation {
    condition     = var.folder_create || var.id != null
    error_message = "Variable `id` cannot be null when `folder_create` is false."
  }
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
      parameters = optional(string)
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
    condition = (
      var.parent == null ||
      startswith(coalesce(var.parent, "-"), "$folder_ids:") ||
      can(regex("(organizations|folders)/[0-9]+", coalesce(var.parent, "-")))
    )
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id, or map to a context variable via $folder_ids:."
  }
}

variable "service_agents_config" {
  description = "Service agents configuration."
  type = object({
    services      = optional(list(string), [])
    create_agents = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "tag_bindings" {
  description = "Tag bindings for this folder, in key => tag value id format."
  type        = map(string)
  default     = null
}
