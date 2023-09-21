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
      principal_tpl    = string
      principalset_tpl = string
    }))
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
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    data_platform_prod = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    gke_dev = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    gke_prod = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    networking = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    project_factory_dev = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    project_factory_prod = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
    security = optional(object({
      branch            = string
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
    data_platform   = optional(bool, false)
    gke             = optional(bool, false)
    project_factory = optional(bool, false)
    sandbox         = optional(bool, false)
    teams           = optional(bool, false)
  })
  default  = {}
  nullable = false
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

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
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

variable "org_policy_tags" {
  # tfdoc:variable:source 0-bootstrap
  description = "Resource management tags for organization policy exceptions."
  type = object({
    key_id   = optional(string)
    key_name = optional(string)
    values   = optional(map(string), {})
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
    tenant      = optional(string, "tenant")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tags" {
  description = "Custome secure tags by key name. The `iam` attribute behaves like the similarly named one at module level."
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

variable "team_folders" {
  description = "Team folders to be created. Format is described in a code comment."
  type = map(object({
    descriptive_name     = string
    group_iam            = map(list(string))
    impersonation_groups = list(string)
    cicd = optional(object({
      branch            = string
      identity_provider = string
      name              = string
      type              = string
    }))
  }))
  default = null
}

variable "tenants" {
  description = "Lightweight tenant definitions."
  type = map(object({
    admin_group_email = string
    descriptive_name  = string
    billing_account   = optional(string)
    organization = optional(object({
      customer_id = string
      domain      = string
      id          = number
    }))
  }))
  nullable = false
  default  = {}
}

variable "tenants_config" {
  description = "Lightweight tenants shared configuration. Roles will be assigned to tenant admin group and service accounts."
  type = object({
    core_folder_roles   = optional(list(string), [])
    tenant_folder_roles = optional(list(string), [])
    top_folder_roles    = optional(list(string), [])
  })
  nullable = false
  default  = {}
}
