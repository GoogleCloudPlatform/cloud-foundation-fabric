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
  type = object({
    # Add validation once API stabilizes
    agent_framework       = string
    class_methods         = optional(list(any), [])
    environment_variables = optional(map(string), {})
    python_version        = optional(string, "3.12")
    secret_environment_variables = optional(map(object({
      secret_id = string
      version   = optional(string, "latest")
    })), {})
  })
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

variable "generate_pickle" {
  description = "Generate the pickle file from a source file."
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

variable "service_account_config" {
  description = "Service account configurations."
  type = object({
    create = optional(bool, true)
    email  = optional(string)
    name   = optional(string)
    roles = optional(list(string), [
      "roles/aiplatform.user",
      "roles/storage.objectViewer",
      # TODO: remove when b/441480710 is solved
      "roles/viewer"
    ])
  })
  nullable = false
  default  = {}
}

variable "source_files" {
  description = "The to source files path and names."
  type = object({
    dependencies        = optional(string, "dependencies.tar.gz")
    path                = optional(string, "./src")
    pickle_out          = optional(string, "pickle.pkl")
    pickle_src          = optional(string, "agent.py")
    pickle_src_var_name = optional(string, "local_agent")
    requirements        = optional(string, "requirements.txt")
  })
  nullable = false
  default  = {}
}
