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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
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
      principal_branch = string
      principal_repo   = string
    }))
    service_accounts = object({
      resman-r = string
    })
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
    no_iam       = optional(bool, false)
  })
  nullable = false
}

variable "cicd_repositories" {
  description = "CI/CD repository configuration. Identity providers reference keys in the `automation.federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed."
  type = object({
    data_platform_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    data_platform_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gke_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gke_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gcve_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    gcve_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    networking = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    project_factory_dev = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    project_factory_prod = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    }))
    security = optional(object({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
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
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    gcve_network_admin            = string
    organization_admin_viewer     = string
    service_project_network_admin = string
    storage_viewer                = string
  })
  default = null
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    checklist_data    = optional(string)
    top_level_folders = optional(string)
  })
  nullable = false
  default  = {}
}

variable "fast_features" {
  description = "Selective control for top-level FAST features."
  type = object({
    data_platform   = optional(bool, false)
    gke             = optional(bool, false)
    gcve            = optional(bool, false)
    project_factory = optional(bool, false)
    sandbox         = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "folder_iam" {
  description = "Authoritative IAM for top-level folders."
  type = object({
    data_platform = optional(map(list(string)), {})
    gcve          = optional(map(list(string)), {})
    gke           = optional(map(list(string)), {})
    sandbox       = optional(map(list(string)), {})
    security      = optional(map(list(string)), {})
    network       = optional(map(list(string)), {})
  })
  nullable = false
  default  = {}
}

variable "groups" {
  # tfdoc:variable:source 0-bootstrap
  # https://cloud.google.com/docs/enterprise/setup-checklist
  description = "Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated."
  type = object({
    gcp-billing-admins      = optional(string, "gcp-billing-admins")
    gcp-devops              = optional(string, "gcp-devops")
    gcp-network-admins      = optional(string, "gcp-vpc-network-admins")
    gcp-organization-admins = optional(string, "gcp-organization-admins")
    gcp-security-admins     = optional(string, "gcp-security-admins")
  })
  nullable = false
  default  = {}
}

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    bq      = optional(string, "EU")
    gcs     = optional(string, "EU")
    logging = optional(string, "global")
    pubsub  = optional(list(string), [])
  })
  nullable = false
  default  = {}
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

variable "tag_names" {
  description = "Customized names for resource management tags."
  type = object({
    context     = optional(string, "context")
    environment = optional(string, "environment")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tags" {
  description = "Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level."
  type = map(object({
    description = optional(string, "Managed by the Terraform organization module.")
    iam         = optional(map(list(string)), {})
    values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}

variable "top_level_folders" {
  description = "Additional top-level folders. Keys are used for service account and bucket names, values implement the folders module interface with the addition of the 'automation' attribute."
  type = map(object({
    name = string
    automation = optional(object({
      enable                      = optional(bool, true)
      sa_impersonation_principals = optional(list(string), [])
    }), {})
    contacts              = optional(map(any), {})
    firewall_policy       = optional(map(any))
    logging_data_access   = optional(map(any), {})
    logging_exclusions    = optional(map(any), {})
    logging_sinks         = optional(map(any), {})
    iam                   = optional(map(any), {})
    iam_bindings          = optional(map(any), {})
    iam_bindings_additive = optional(map(any), {})
    iam_by_principals     = optional(map(any), {})
    org_policies          = optional(map(any), {})
    tag_bindings          = optional(map(any), {})
  }))
  nullable = false
  default  = {}
}
