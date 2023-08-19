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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the organization-level bootstrap stage."
  type = object({
    outputs_bucket          = string
    project_id              = string
    project_number          = string
    federated_identity_pool = string
    federated_identity_providers = map(object({
      audiences        = list(string)
      issuer           = string
      issuer_uri       = string
      name             = string
      principal_tpl    = string
      principalset_tpl = string
    }))
  })
}

variable "billing_account" {
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
    no_iam       = optional(bool, false)
  })
  nullable = false
}

variable "cicd_repositories" {
  description = "CI/CD repository configuration. Identity providers reference keys in the `federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed."
  type = object({
    bootstrap = optional(object({
      branch            = optional(string)
      identity_provider = string
      name              = string
      type              = string
    }))
    resman = optional(object({
      branch            = optional(string)
      identity_provider = string
      name              = string
      type              = string
    }))
  })
  default = null
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || try(v.name, null) != null
    ])
    error_message = "Non-null repositories need a non-null name."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || (
        try(v.identity_provider, null) != null
        ||
        try(v.type, null) == "sourcerepo"
      )
    ])
    error_message = "Non-null repositories need a non-null provider unless type is 'sourcerepo'."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.cicd_repositories, {}) :
      v == null || (
        contains(["github", "gitlab", "sourcerepo"], coalesce(try(v.type, null), "null"))
      )
    ])
    error_message = "Invalid repository type, supported types: 'github' 'gitlab' or 'sourcerepo'."
  }
}

variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the organization level, in key => id format."
  type = object({
    service_project_network_admin = string
    tenant_network_admin          = string
  })
  default = null
}

variable "fast_features" {
  # tfdoc:variable:source 0-bootstrap
  description = "Selective control for top-level FAST features."
  type = object({
    data_platform   = optional(bool, true)
    gke             = optional(bool, true)
    project_factory = optional(bool, true)
    sandbox         = optional(bool, true)
    teams           = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "federated_identity_providers" {
  description = "Workload Identity Federation pools. The `cicd_repositories` variable references keys here."
  type = map(object({
    attribute_condition = optional(string)
    issuer              = string
    custom_settings = optional(object({
      issuer_uri = optional(string)
      audiences  = optional(list(string), [])
    }), {})
  }))
  default  = {}
  nullable = false
}

variable "group_iam" {
  description = "Tenant-level custom group IAM settings in group => [roles] format."
  type        = map(list(string))
  default     = {}
}

variable "groups" {
  # tfdoc:variable:source 0-bootstrap
  # https://cloud.google.com/docs/enterprise/setup-checklist
  description = "Group names or emails to grant organization-level permissions. If just the name is provided, the default organization domain is assumed."
  type = object({
    gcp-devops          = optional(string)
    gcp-network-admins  = optional(string)
    gcp-security-admins = optional(string)
  })
  default  = {}
  nullable = false
}

variable "iam" {
  description = "Tenant-level custom IAM settings in role => [principal] format."
  type        = map(list(string))
  default     = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here. These are the defaults set at the organization level, and can be overridden via the tenant config variable."
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
  # tfdoc:variable:source 0-bootstrap
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
  description = "Optional parents for projects created here in folders/nnnnnnn format. Null values will use the tenant folder as parent."
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
  description = "Tenant configuration. Short name must be 4 characters or less. If `short_name_is_prefix` is true, short name must be 9 characters or less, and will be used as the prefix as is."
  type = object({
    descriptive_name = string
    groups = object({
      gcp-admins          = string
      gcp-devops          = optional(string)
      gcp-network-admins  = optional(string)
      gcp-security-admins = optional(string)
    })
    short_name           = string
    short_name_is_prefix = optional(bool, false)
    fast_features = optional(object({
      data_platform   = optional(bool)
      gke             = optional(bool)
      project_factory = optional(bool)
      sandbox         = optional(bool)
      teams           = optional(bool)
    }), {})
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
    condition     = (var.tenant_config.short_name_is_prefix && length(var.tenant_config.short_name) < 10) || length(var.tenant_config.short_name) < 5
    error_message = "Short name must be a string of 4 characters or less."
  }
}


variable "test_principal" {
  description = "Used when testing to bypass the data source returning the current identity."
  type        = string
  default     = null
}
