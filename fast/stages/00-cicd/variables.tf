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

variable "automation" {
  # tfdoc:variable:source 00-bootstrap
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

variable "cicd_repositories" {
  description = "CI/CD repository configuration. Identity providers reference keys in the `federated_identity_providers` variable. Set to null to disable, or set individual repositories to null if not needed."
  type = object({
    bootstrap = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
    resman = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
    networking = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
    security = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
    data-platform = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
    project-factory = object({
      branch       = string
      name         = string
      description  = string
      type         = string
      create       = bool
      create_group = bool
    })
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
        contains(["github", "gitlab", "sourcerepo"], coalesce(try(v.type, null), "null"))
      )
    ])
    error_message = "Invalid repository type, supported types: 'github' 'gitlab' or 'sourcerepo'."
  }
}

variable "gitlab" {
  description = "Gitlab settings"
  type = object({
    url                    = string
    project_visibility     = string
    shared_runners_enabled = bool
  })
  default = {
    url                    = "https://gitlab.com"
    project_visibility     = "private"
    shared_runners_enabled = true
  }
}

variable "github" {
  description = "GitHub settings"
  type = object({
    url        = string
    visibility = string
  })
  default = {
    url        = null
    visibility = "private"
  }
}

variable "custom_roles" {
  # tfdoc:variable:source 00-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    service_project_network_admin = string
  })
  default = null
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable"
  type        = string
  default     = null
}
