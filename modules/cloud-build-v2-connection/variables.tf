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

variable "annotations" {
  description = "Annotations."
  type        = map(string)
  default     = {}
}

variable "connection_config" {
  description = "Connection configuration."
  type = object({
    bitbucket_cloud = optional(object({
      app_installation_id                       = optional(string)
      authorizer_credential_secret_version      = string
      read_authorizer_credential_secret_version = string
      webhook_secret_secret_version             = string
      workspace                                 = string
    }))
    bitbucket_data_center = optional(object({
      authorizer_credential_secret_version      = string
      host_uri                                  = string
      read_authorizer_credential_secret_version = string
      service                                   = optional(string)
      ssl_ca                                    = optional(string)
      webhook_secret_secret_version             = optional(string)
    }))
    github = optional(object({
      app_installation_id                  = optional(string)
      authorizer_credential_secret_version = optional(string)
    }))
    github_enterprise = optional(object({
      app_id                        = optional(string)
      app_installation_id           = optional(string)
      app_slug                      = optional(string)
      host_uri                      = string
      private_key_secret_version    = optional(string)
      service                       = optional(string)
      ssl_ca                        = optional(string)
      webhook_secret_secret_version = optional(string)
    }))
    gitlab = optional(object({
      host_uri                                  = optional(string)
      webhook_secret_secret_version             = string
      read_authorizer_credential_secret_version = string
      authorizer_credential_secret_version      = string
      service                                   = optional(string)
      ssl_ca                                    = optional(string)
    }))
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      (try(var.connection_config.bitbucket_cloud, null) == null ? 0 : 1) +
      (try(var.connection_config.bitbucket_data_center, null) == null ? 0 : 1) +
      (try(var.connection_config.github, null) == null ? 0 : 1) +
      (try(var.connection_config.github_enterprise, null) == null ? 0 : 1) +
      (try(var.connection_config.gitlab, null) == null ? 0 : 1) == 1
    )
    error_message = "One and only one of bitbucket_cloud, bitbucket_data_center, github, github_enterprise, gitlab can be defined."
  }
}

variable "connection_create" {
  description = "Create connection."
  type        = bool
  default     = true
}


variable "context" {
  description = "Context-specific interpolations."
  type = object({
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "disabled" {
  description = "Flag indicating whether the connection is disabled or not."
  type        = bool
  default     = false
}

variable "location" {
  description = "Location."
  type        = string
}

variable "name" {
  description = "Name."
  type        = string
}

variable "prefix" {
  description = "Prefix."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "repositories" {
  description = "Repositories."
  type = map(object({
    remote_uri  = string
    annotations = optional(map(string), {})
    triggers = optional(map(object({
      approval_required = optional(bool, false)
      description       = optional(string)
      pull_request = optional(object({
        branch          = optional(string)
        invert_regex    = optional(string)
        comment_control = optional(string)
      }))
      push = optional(object({
        branch       = optional(string)
        invert_regex = optional(string)
        tag          = optional(string)
      }))
      disabled           = optional(bool, false)
      filename           = string
      include_build_logs = optional(string)
      substitutions      = optional(map(string), {})
      service_account    = optional(string)
      tags               = optional(map(string))
    })), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([for k1, v1 in var.repositories :
      alltrue([for k2, v2 in v1.triggers :
        contains(["INCLUDE_BUILD_LOGS_UNSPECIFIED",
          "INCLUDE_BUILD_LOGS_WITH_STATUS"],
    coalesce(v2.include_build_logs, "INCLUDE_BUILD_LOGS_UNSPECIFIED"))])])
    error_message = "Possible values for include_build_logs are: INCLUDE_BUILD_LOGS_UNSPECIFIED, INCLUDE_BUILD_LOGS_WITH_STATUS."
  }

  validation {
    condition = alltrue([for k1, v1 in var.repositories :
      alltrue([for k2, v2 in v1.triggers :
        contains(["COMMENTS_DISABLED",
          "COMMENTS_ENABLED", "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"],
    try(v2.push.comment_control, "COMMENTS_DISABLED"))])])
    error_message = "Possible values for include_build_logs are: COMMENTS_DISABLED, COMMENTS_ENABLED, COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY."
  }

  validation {
    condition = alltrue([for k1, v1 in var.repositories :
      alltrue([for k2, v2 in v1.triggers : (v2.push == null) != (v2.pull_request == null)])
    ])
    error_message = "One of pull or push needs to be populated for a trigger."
  }
}
