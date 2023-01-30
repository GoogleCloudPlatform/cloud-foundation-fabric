# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Variables definition.

variable "access_policy" {
  description = "Access Policy name, set to null if creating one."
  type        = string
  default     = null
}

variable "access_policy_create" {
  description = "Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format."
  type = object({
    parent = string
    title  = string
    scopes = optional(list(string))
  })
  default = null
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data."
  type        = string
  default     = "data"
}

variable "enable_features" {
  description = "Flag to enable features on the solution."
  type = object({
    kms      = bool
    log_sink = bool
  })
  default = {
    kms      = true
    log_sink = true
  }
}
variable "folder_create" {
  description = "Provide values if folder creation is needed, uses existing folder if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    display_name = string
    parent       = string
  })
  default = null
}

variable "folder_id" {
  description = "Folder ID in case you use folder_create=null."
  type        = string
  default     = null
}

variable "groups" {
  description = "User groups."
  type        = map(string)
  default = {
    #TODO data-analysts  = "gcp-data-analysts"
    data-engineers = "gcp-data-engineers"
    data-security  = "gcp-data-security"
  }
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name."
  type = map(object({
    iam             = optional(map(list(string)), {})
    labels          = optional(map(string), {})
    locations       = optional(list(string), ["global", "europe", "europe-west1"])
    rotation_period = optional(string, "7776000s")
  }))
  default = {}
}

variable "log_locations" {
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    bq      = optional(string, "europe")
    storage = optional(string, "europe")
    logging = optional(string, "global")
    pubsub  = optional(string, "global")
  })
  default = {
    bq      = "europe"
    storage = "europe"
    logging = "global"
    pubsub  = null
  }
  nullable = false
}

variable "log_sinks" {
  description = "Org-level log sinks, in name => {type, filter} format."
  type = map(object({
    filter = string
    type   = string
  }))
  default = {
    audit-logs = {
      filter = "logName:\"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName:\"/logs/cloudaudit.googleapis.com%2Fsystem_event\""
      type   = "bigquery"
    }
    vpc-sc = {
      filter = "protoPayload.metadata.@type=\"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata\""
      type   = "bigquery"
    }
  }
  validation {
    condition = alltrue([
      for k, v in var.log_sinks :
      contains(["bigquery", "logging", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'pubsub', 'storage'."
  }
}

variable "organization" {
  description = "Organization details."
  type = object({
    domain = string
    id     = string
  })
}

variable "prefix" {
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "projects_create" {
  description = "Provide values if projects creation is needed, uses existing project if null. Projects will be created in the shielded folder."
  type = object({
    billing_account_id = string
  })
  default = null
}

variable "projects_id" {
  description = "Project id, references existing projects if `project_create` is null. Projects will be moved into the shielded folder."
  type = object({
    sec-core   = string
    audit-logs = string
  })
  default = null
}

variable "vpc_sc_access_levels" {
  description = "VPC SC access level definitions."
  type = map(object({
    combining_function = optional(string)
    conditions = optional(list(object({
      device_policy = optional(object({
        allowed_device_management_levels = optional(list(string))
        allowed_encryption_statuses      = optional(list(string))
        require_admin_approval           = bool
        require_corp_owned               = bool
        require_screen_lock              = optional(bool)
        os_constraints = optional(list(object({
          os_type                    = string
          minimum_version            = optional(string)
          require_verified_chrome_os = optional(bool)
        })))
      }))
      ip_subnetworks         = optional(list(string), [])
      members                = optional(list(string), [])
      negate                 = optional(bool)
      regions                = optional(list(string), [])
      required_access_levels = optional(list(string), [])
    })), [])
    description = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_egress_policies" {
  description = "VPC SC egress policy defnitions."
  type = map(object({
    from = object({
      identity_type = optional(string, "ANY_IDENTITY")
      identities    = optional(list(string))
    })
    to = object({
      operations = optional(list(object({
        method_selectors = optional(list(string))
        service_name     = string
      })), [])
      resources              = optional(list(string))
      resource_type_external = optional(bool, false)
    })
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_ingress_policies" {
  description = "VPC SC ingress policy defnitions."
  type = map(object({
    from = object({
      access_levels = optional(list(string), [])
      identity_type = optional(string)
      identities    = optional(list(string))
      resources     = optional(list(string), [])
    })
    to = object({
      operations = optional(list(object({
        method_selectors = optional(list(string))
        service_name     = string
      })), [])
      resources = optional(list(string))
    })
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_perimeters" {
  description = "VPC SC regular perimeter definitions for shielded folder. All projects in the perimeter will be added."
  type = object({
    access_levels    = optional(list(string), [])
    egress_policies  = optional(list(string), [])
    ingress_policies = optional(list(string), [])
  })
  default  = {}
  nullable = false
}
