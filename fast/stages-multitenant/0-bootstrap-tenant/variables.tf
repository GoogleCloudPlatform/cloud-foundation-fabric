/**
 * Copyright 2022 Google LLC
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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation" {
  # tfdoc:variable:source 0-0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket          = string
    project_id              = string
    project_number          = string
    federated_identity_pool = string
    federated_identity_providers = map(object({
      issuer           = string
      issuer_uri       = string
      name             = string
      principal_tpl    = string
      principalset_tpl = string
    }))
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}


variable "custom_roles" {
  # tfdoc:variable:source 0-0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    service_project_network_admin = string
  })
  default = null
}

variable "fast_features" {
  # tfdoc:variable:source 0-0-bootstrap
  description = "Selective control for top-level FAST features."
  type = object({
    data_platform   = bool
    gke             = bool
    project_factory = bool
    sandbox         = bool
    teams           = bool
  })
  default = {
    data_platform   = true
    gke             = true
    project_factory = true
    sandbox         = true
    teams           = true
  }
  # nullable = false
}

variable "locations" {
  # tfdoc:variable:source 0-0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    bq      = string
    gcs     = string
    logging = string
    pubsub  = list(string)
  })
  default = {
    bq      = "EU"
    gcs     = "EU"
    logging = "global"
    pubsub  = []
  }
  nullable = false
}

# See https://cloud.google.com/architecture/exporting-stackdriver-logging-for-security-and-access-analytics
# for additional logging filter examples
variable "log_sinks" {
  description = "Tenant-level log sinks, in name => {type, filter} format."
  type = map(object({
    filter = string
    type   = string
  }))
  default = {
    audit-logs = {
      filter = "logName:\"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName:\"/logs/cloudaudit.googleapis.com%2Fsystem_event\""
      type   = "logging"
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
  # tfdoc:variable:source 0-0-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "project_parent_ids" {
  description = "Optional parents for projects created here in folders/nnnnnnn format. Null values will use the organization as parent."
  type = object({
    automation = string
    logging    = string
  })
  default = {
    automation = null
    logging    = null
  }
  nullable = false
}

variable "tag_keys" {
  # tfdoc:variable:source 1-resman
  description = "Organization tag keys."
  type = object({
    context     = string
    environment = string
    tenant      = string
  })
  nullable = false
}

variable "tag_names" {
  # tfdoc:variable:source 1-resman
  description = "Customized names for resource management tags."
  type = object({
    context     = string
    environment = string
    tenant      = string
  })
  nullable = false
}

variable "tag_values" {
  # tfdoc:variable:source 1-resman
  description = "Organization resource management tag values."
  type        = map(string)
  nullable    = false
}

variable "tenant_config" {
  description = "Tenant configuration. Short name must be 4 characters or less."
  type = object({
    descriptive_name = string
    groups = object({
      gcp-admins          = string
      gcp-devops          = optional(string)
      gcp-network-admins  = optional(string)
      gcp-security-admins = optional(string)
    })
    short_name = string
    cicd = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    group_iam = optional(map(list(string)), {})
    iam       = optional(map(list(string)), {})
    locations = optional(object({
      bq      = optional(string)
      gcs     = optional(string)
      logging = optional(string)
      pubsub  = optional(list(string))
    }), {})
  })
  nullable = false
  validation {
    condition = alltrue([
      for a in ["descriptive_name", "groups", "short_name"] :
      var.tenant_config[a] != null
    ])
    error_message = "Non-optional members must not be null."
  }
  validation {
    condition     = length(var.tenant_config.short_name) < 5
    error_message = "Short name must be a string of 4 characters or less."
  }
}


variable "test_principal" {
  description = "Used when testing to bypass the data source returning the current identity."
  type        = string
  default     = null
}
