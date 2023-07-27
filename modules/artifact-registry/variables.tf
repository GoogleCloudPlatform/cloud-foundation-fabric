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

variable "description" {
  description = "An optional description for the repository."
  type        = string
  default     = "Terraform-managed registry"
}

variable "format" {
  description = "Repository format."
  type = object({
    docker = optional(object({
      immutable_tags = optional(bool)
    }))
    maven = optional(object({
      allow_snapshot_overrides = bool
      version_policy           = string
    }))
    python = optional(object({}))
    go     = optional(object({}))
    npm    = optional(object({}))
    apt    = optional(object({}))
    yum    = optional(object({}))
    kfp    = optional(object({}))
  })
  # todo(jccb) validate only one of these is set
  #
}

variable "mode" {
  type = object({
    standard = optional(bool, false)
    remote   = optional(bool, false)
    virtual = optional(map(object({
      repository = string
      priority   = number
    })))
  })
  default  = { standard = true }
  nullable = false
  # todo(jccb) validate only remote or virtual is set
  # todo(jccb) validate format in (docker, mave, npm, python) if remote  is set
}

variable "encryption_key" {
  description = "The KMS key name to use for encryption at rest."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "id" {
  description = "Repository id."
  type        = string
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

variable "project_id" {
  description = "Registry project id."
  type        = string
}
