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

variable "cleanup_policies" {
  description = "Object containing details about the cleanup policies for an Artifact Registry repository."
  type = map(object({
    action = string
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
      package_name_prefixes = optional(list(string))
      version_name_prefixes = optional(list(string))
    }))
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    }))
  }))

  default = null
}

variable "cleanup_policy_dry_run" {
  description = "If true, the cleanup pipeline is prevented from deleting versions in this repository."
  type        = bool
  default     = null
}

variable "description" {
  description = "An optional description for the repository."
  type        = string
  default     = "Terraform-managed registry"
}

variable "encryption_key" {
  description = "The KMS key name to use for encryption at rest."
  type        = string
  default     = null
}

variable "format" {
  description = "Repository format."
  type = object({
    apt = optional(object({
      remote = optional(object({
        # custom_repository = optional(string) # still not available in provider
        public_repository = string # "BASE path"

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(bool)
    }))
    docker = optional(object({
      remote = optional(object({
        public_repository = optional(string)
        custom_repository = optional(string)

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(object({
        immutable_tags = optional(bool)
      }))
      virtual = optional(map(object({
        repository = string
        priority   = number
      })))
    }))
    kfp = optional(object({
      standard = optional(bool)
    }))
    generic = optional(object({
      standard = optional(bool)
    }))
    go = optional(object({
      standard = optional(bool)
    }))
    googet = optional(object({
      standard = optional(bool)
    }))
    maven = optional(object({
      remote = optional(object({
        public_repository = optional(string)
        custom_repository = optional(string)

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(object({
        allow_snapshot_overwrites = optional(bool)
        version_policy            = optional(string)
      }))
      virtual = optional(map(object({
        repository = string
        priority   = number
      })))
    }))
    npm = optional(object({
      remote = optional(object({
        public_repository = optional(string)
        custom_repository = optional(string)

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(bool)
      virtual = optional(map(object({
        repository = string
        priority   = number
      })))
    }))
    python = optional(object({
      remote = optional(object({
        public_repository = optional(string)
        custom_repository = optional(string)

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(bool)
      virtual = optional(map(object({
        repository = string
        priority   = number
      })))
    }))
    yum = optional(object({
      remote = optional(object({
        # custom_repository = optional(string) # still not available in provider
        public_repository = string # "BASE path"

        disable_upstream_validation = optional(bool)
        upstream_credentials = optional(object({
          username                = string
          password_secret_version = string
        }))
      }))
      standard = optional(bool)
    }))
  })
  nullable = false
  validation {
    condition = (
      length([for k, v in var.format : k if v != null]) == 1
    )
    error_message = "Multiple or zero formats are not supported."
  }
  validation {
    condition = alltrue([
      for k, v in var.format :
      length([for kk, vv in v : k if vv != null]) == 1
      if v != null
    ])
    error_message = "Repository can only be one of standard, remote or virtual."
  }
  validation {
    condition = alltrue([
      for k, v in var.format :
      (try(v.remote.public_repository, null) == null) != (try(v.remote.custom_repository, null) == null)
      if try(v.remote, null) != null
    ])
    error_message = "Remote repositories must specify exactly one of public_repository and custom_repository."
  }
}

variable "labels" {
  description = "Labels to be attached to the registry."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Registry location. Use `gcloud beta artifacts locations list' to get valid values."
  type        = string
}

variable "name" {
  description = "Registry name."
  type        = string
}

variable "project_id" {
  description = "Registry project id."
  type        = string
}
