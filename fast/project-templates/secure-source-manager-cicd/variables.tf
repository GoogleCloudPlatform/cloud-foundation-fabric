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

variable "build_pool_config" {
  description = "Cloud Build private worker pool, peered with the VPC over private service access."
  type = object({
    disk_size_gb   = optional(number, 100)
    machine_type   = optional(string, "e2-standard-2")
    peered_network = string
    psa_range_size = optional(string, "/26")
  })
  nullable = false
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    ca_pools            = optional(map(string), {})
    custom_roles        = optional(map(string), {})
    iam_principals      = optional(map(string), {})
    locations           = optional(map(string), {})
    networks            = optional(map(string), {})
    project_ids         = optional(map(string), {})
    service_account_ids = optional(map(string), {})
    subnets             = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "load_balancer_config" {
  description = "Internal proxy load balancer pair in front of the instance service attachments, for the build workers behind their peering."
  type = object({
    address    = optional(string)
    network    = string
    subnetwork = string
  })
  nullable = false
}

variable "location" {
  description = "Region for the instance, the load balancers, the build pool, and any CA pool."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Base name for the instance and the build pool, prefixed with the prefix."
  type        = string
  nullable    = false
  default     = "ssm-0"
}

variable "prefix" {
  description = "Optional prefix for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "projects_config" {
  description = "Instance project with its number, and optional build project defaulting to the instance project. The automation principal is derived from the provider identity when null."
  type = object({
    build = optional(object({
      project_id = string
    }))
    ssm = object({
      number               = number
      project_id           = string
      automation_principal = optional(string)
    })
  })
  nullable = false
}

variable "repositories_config" {
  description = "Repositories, each with its own service account and the build identities its pipelines run as."
  type = map(object({
    description = optional(string)
    branch_rules = optional(map(object({
      include_pattern           = string
      allow_stale_reviews       = optional(bool)
      disabled                  = optional(bool, false)
      minimum_approvals_count   = optional(number)
      minimum_reviews_count     = optional(number)
      require_comments_resolved = optional(bool)
      require_linear_history    = optional(bool)
      require_pull_request      = optional(bool)
    })), {})
    build_identities = optional(map(object({
      description = optional(string)
      # full service account ids the identity may impersonate, granted as
      # roles/iam.serviceAccountTokenCreator on each; the owner of the target
      # account decides whether it accepts this, via a delegation naming this
      # configuration's automation account (README, delegation section)
      impersonate_service_accounts = optional(list(string), [])
      # role granted on the identity's own repository (defaulting to repoWriter
      # so pull request builds can post plan comments); null skips the grant
      repository_role = optional(string, "roles/securesourcemanager.repoWriter")
    })), {})
    deletion_policy = optional(string)
    initial_config = optional(object({
      default_branch = optional(string)
      gitignores     = optional(list(string))
      license        = optional(string)
      readme         = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "ssm_config" {
  description = "Instance configuration; ca_pool_id, custom_host_config and psc_allowed_projects are immutable."
  type = object({
    ca_pool_id = optional(string)
    custom_host_config = optional(object({
      api      = string
      git_http = string
      git_ssh  = string
      html     = string
    }))
    deletion_policy      = optional(string)
    psc_allowed_projects = optional(list(string))
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      var.ssm_config.custom_host_config == null ||
      var.ssm_config.ca_pool_id != null
    )
    error_message = "Custom hostnames require ca_pool_id to sign their certificate."
  }
}
