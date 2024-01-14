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
    apt = optional(object({}))
    docker = optional(object({
      immutable_tags = optional(bool)
    }))
    kfp = optional(object({}))
    go  = optional(object({}))
    maven = optional(object({
      allow_snapshot_overwrites = optional(bool)
      version_policy            = optional(string)
    }))
    npm    = optional(object({}))
    python = optional(object({}))
    yum    = optional(object({}))
  })
  nullable = false
  default  = { docker = {} }
  validation {
    condition = (
      length([for k, v in var.format : k if v != null]) == 1
    )
    error_message = "Multiple or zero formats are not supported."
  }
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
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

variable "mode" {
  description = "Repository mode."
  type = object({
    standard = optional(bool)
    remote   = optional(bool)
    virtual = optional(map(object({
      repository = string
      priority   = number
    })))
  })
  nullable = false
  default  = { standard = true }
  validation {
    condition = (
      length([for k, v in var.mode : k if v != null && v != false]) == 1
    )
    error_message = "Multiple or zero modes are not supported."
  }
}

variable "name" {
  description = "Registry name."
  type        = string
}

variable "project_id" {
  description = "Registry project id."
  type        = string
}
