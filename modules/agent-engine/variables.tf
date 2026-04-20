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

variable "agent_engine_config" {
  description = "The agent configuration. Supported values for agent_framework: 'google-adk', 'langchain', 'langgraph', 'ag2', 'llama-index', 'custom'."
  type = object({
    # Add validation once API stabilizes
    agent_framework       = optional(string)
    class_methods         = optional(string)
    container_concurrency = optional(number)
    environment_variables = optional(map(string), {})
    max_instances         = optional(number)
    min_instances         = optional(number)
    python_version        = optional(string, "3.13")
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
  default  = {}
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
    custom_roles            = optional(map(string), {})
    iam_principals          = optional(map(string), {})
    locations               = optional(map(string), {})
    kms_keys                = optional(map(string), {})
    models                  = optional(map(string), {})
    networks                = optional(map(string), {})
    project_ids             = optional(map(string), {})
    psc_network_attachments = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "deployment_config" {
  description = "The deployment configuration."
  type = object({
    container_config = optional(object({
      image_uri = string
    }))
    package_config = optional(object({
      are_paths_local   = optional(bool, true)
      dependencies_path = optional(string, "./src/dependencies.tar.gz")
      pickle_path       = optional(string, "./src/pickle.pkl")
      requirements_path = optional(string, "./src/requirements.txt")
    }))
    source_files_config = optional(object({
      source_path = optional(string)
      developer_connect_config = optional(object({
        git_repository_link = string
        dir                 = string
        revision            = string
      }))
      python_spec = optional(object({
        entrypoint_module = optional(string, "agent")
        entrypoint_object = optional(string, "agent")
        requirements_file = optional(string, "requirements.txt")
      }))
      image_spec = optional(object({
        build_args = optional(map(string), {})
      }))
    }))

  })
  nullable = false
  default  = {}
  validation {
    condition = (
      (var.deployment_config.container_config != null ? 1 : 0) +
      (var.deployment_config.package_config != null ? 1 : 0) +
      (var.deployment_config.source_files_config != null ? 1 : 0)
    ) <= 1
    error_message = "You can provide at most one of 'container_config', 'package_config' or 'source_files_config'."
  }
  validation {
    condition = (
      var.deployment_config.source_files_config == null ? true : (
        (var.deployment_config.source_files_config.source_path != null ? 1 : 0) +
        (var.deployment_config.source_files_config.developer_connect_config != null ? 1 : 0)
      ) <= 1
    )
    error_message = "Only one of 'source_path' or 'developer_connect_config' can be specified within 'source_files_config'."
  }
  validation {
    condition = (
      var.deployment_config.source_files_config == null ? true : (
        (var.deployment_config.source_files_config.python_spec != null ? 1 : 0) +
        (var.deployment_config.source_files_config.image_spec != null ? 1 : 0)
      ) <= 1
    )
    error_message = "Only one of 'python_spec' or 'image_spec' can be specified within 'source_files_config'."
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

variable "memory_bank_config" {
  description = "Configuration for the memory bank."
  type = object({
    disable_memory_revisions = optional(bool)
    generation_config = optional(object({
      model = string
    }))
    similarity_search_config = optional(object({
      embedding_model = string
    }))
    ttl_config = optional(object({
      default_ttl                 = optional(string)
      memory_revision_default_ttl = optional(string)
      granular_ttl_config = optional(object({
        create_ttl           = optional(string)
        generate_created_ttl = optional(string)
        generate_updated_ttl = optional(string)
      }))
    }))
  })
  default = null
}

variable "name" {
  description = "The name of the agent."
  type        = string
  nullable    = false
}

variable "networking_config" {
  description = "Networking configuration."
  type = object({
    network_attachment_id = string
    # key is the domain
    dns_peering_configs = optional(map(object({
      target_network_name = string
      target_project_id   = optional(string)
    })))
  })
  default = null
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
