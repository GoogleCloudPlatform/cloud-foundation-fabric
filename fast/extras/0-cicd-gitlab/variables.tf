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

variable "commit_config" {
  description = "Configure commit metadata."
  type = object({
    author  = optional(string, "FAST loader")
    email   = optional(string, "fast-loader@fast.gcp.tf")
    message = optional(string, "FAST initial loading")
  })
  default  = {}
  nullable = false
}

variable "gitlab_config" {
  description = "Gitlab config."
  type = object({
    access_token = string
    hostname     = optional(string, "gitlab.gcp.example.com")
    ssh_port     = optional(number, 2222)
  })
}

variable "groups" {
  description = "Gitlab groups."
  type = map(object({
    name        = string
    path        = string
    description = string
  }))
}

variable "modules_config" {
  description = "Gitlab modules config."
  type = object({
    bootstrap     = optional(bool, true)
    module_prefix = optional(string, "")
    group         = optional(string)
    project_name  = string
    source_ref    = optional(string)
    key_config = optional(object({
      create_key     = optional(bool, false)
      create_secrets = optional(bool, false)
      keypair_path   = optional(string)
    }), {})
  })
  default = null
  validation {
    condition = (
      var.modules_config == null
      ||
      try(var.modules_config.project_name, null) != null
    )
    error_message = "Modules configuration requires a modules repository name."
  }
}

variable "projects" {
  description = "Gitlab projects to create."
  type = map(object({
    create_options = optional(object({
      allow = optional(object({
        auto_merge   = optional(bool)
        merge_commit = optional(bool)
        rebase_merge = optional(bool)
        squash_merge = optional(bool)
      }))
      auto_init   = optional(bool)
      description = optional(string)
      features = optional(object({
        issues   = optional(bool)
        projects = optional(bool)
        wiki     = optional(bool)
      }))
      templates = optional(object({
        gitignore = optional(string, "Terraform")
        license   = optional(string)
        repository = optional(object({
          name  = string
          owner = string
        }))
      }), {})
      visibility = optional(string, "private")
    }))
    group            = string
    populate_from    = optional(string)
    populate_samples = optional(bool, false)
    workflow_file    = optional(string, null)
  }))
  default  = {}
  nullable = true
  validation {
    condition = alltrue([
      for k, v in var.projects :
      try(regex("^[a-zA-Z0-9-_.]+$", k), null) != null
    ])
    error_message = "Project names must match '^[a-zA-Z0-9_.]+$'."
  }
}
