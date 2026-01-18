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

variable "agent_engine_config" {
  description = "The agent configuration."
  type = object({
    # Add validation once API stabilizes
    agent_framework       = string
    class_methods         = optional(list(any), [])
    container_concurrency = optional(number)
    environment_variables = optional(map(string), {})
    max_instances         = optional(number)
    min_instances         = optional(number)
    python_version        = optional(string, "3.12")
    resource_limits = optional(object({
      cpu    = string
      memory = string
    }))
    secret_environment_variables = optional(map(object({
      secret_id = string
      version   = optional(string, "latest")
    })), {})
  })
  nullable = false
}

variable "bucket_config" {
  description = "The GCS bucket configuration."
  type = object({
    create                      = optional(bool, true)
    deletion_protection         = optional(bool, true)
    name                        = optional(string)
    uniform_bucket_level_access = optional(bool, true)
  })
  nullable = false
  default  = {}
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    project_ids    = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "deployment_files" {
  description = "The to source files path and names."
  type = object({
    package_config = optional(object({
      are_paths_local   = optional(bool, true)
      dependencies_path = optional(string, "./src/dependencies.tar.gz")
      pickle_path       = optional(string, "./src/pickle.pkl")
      requirements_path = optional(string, "./src/requirements.txt")
    }), null)
    source_config = optional(object({
      entrypoint_module = optional(string, "agent")
      entrypoint_object = optional(string, "agent")
      requirements_path = optional(string, "requirements.txt")
      source_path       = optional(string, "./src/source.tar.gz")
    }), null)
  })
  nullable = false
  default = {
    package_config = null
    source_config  = {}
  }
  validation {
    condition = (
      var.deployment_files.package_config != null ||
      var.deployment_files.source_config != null
    )
    error_message = "You must provide either 'package_config' or 'source_config'."
  }
  validation {
    condition = !(
      var.deployment_files.package_config != null &&
      var.deployment_files.source_config != null
    )
    error_message = "You cannot specify both 'package_config' and 'source_config' simultaneously."
  }
}

variable "description" {
  description = "The Agent Engine description."
  type        = string
  nullable    = false
  default     = "Terraform managed."
}

variable "encryption_key" {
  description = "The full resource name of the Cloud KMS CryptoKey."
  type        = string
  default     = null
}

variable "managed" {
  description = "Whether the Terraform module should control the code updates."
  type        = bool
  nullable    = false
  default     = true
}

variable "name" {
  description = "The name of the agent."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "The id of the project where to deploy the agent."
  type        = string
  nullable    = false
}

variable "region" {
  description = "The region where to deploy the agent."
  type        = string
  nullable    = false
}
