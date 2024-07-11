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

variable "bucket_config" {
  description = "Enable and configure auto-created bucket. Set fields to null to use defaults."
  type = object({
    force_destroy             = optional(bool)
    lifecycle_delete_age_days = optional(number)
    location                  = optional(string)
  })
  default = null
}

variable "bucket_name" {
  description = "Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null."
  type        = string
  nullable    = false
}

variable "build_environment_variables" {
  description = "A set of key/value environment variable pairs available during build time."
  type        = map(string)
  default     = {}
}

variable "build_worker_pool" {
  description = "Build worker pool, in projects/<PROJECT-ID>/locations/<REGION>/workerPools/<POOL_NAME> format."
  type        = string
  default     = null
}

variable "bundle_config" {
  description = "Cloud function source. Path can point to a GCS object URI, or a local path. A local path to a zip archive will generate a GCS object using its basename, a folder will be zipped and the GCS object name inferred when not specified."
  type = object({
    path = string
    folder_options = optional(object({
      archive_path = optional(string)
      excludes     = optional(list(string))
    }), {})
  })
  nullable = false
  validation {
    condition = (
      var.bundle_config.path != null && (
        # GCS object
        (
          startswith(var.bundle_config.path, "gs://") &&
          endswith(var.bundle_config.path, ".zip")
        )
        ||
        # local folder
        length(fileset(pathexpand(var.bundle_config.path), "**/*")) > 0
        ||
        # local ZIP archive
        (
          try(fileexists(pathexpand(var.bundle_config.path)), null) != null &&
          endswith(var.bundle_config.path, ".zip")
        )
      )
    )
    error_message = "Bundle path must be set to a GCS object URI, a local folder or a local zip file."
  }
}

variable "description" {
  description = "Optional description."
  type        = string
  default     = "Terraform managed."
}

variable "environment_variables" {
  description = "Cloud function environment variables."
  type        = map(string)
  default     = {}
}

variable "function_config" {
  description = "Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout."
  type = object({
    entry_point     = optional(string, "main")
    instance_count  = optional(number, 1)
    memory_mb       = optional(number, 256) # Memory in MB
    cpu             = optional(string, "0.166")
    runtime         = optional(string, "python310")
    timeout_seconds = optional(number, 180)
  })
  default = {
    entry_point     = "main"
    instance_count  = 1
    memory_mb       = 256
    cpu             = "0.166"
    runtime         = "python310"
    timeout_seconds = 180
  }
}

variable "https_security_level" {
  description = "The security level for the function: Allowed values are SECURE_ALWAYS, SECURE_OPTIONAL."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings for topic in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "ingress_settings" {
  description = "Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY ."
  type        = string
  default     = null
}

variable "kms_key" {
  description = "Resource name of a KMS crypto key (managed by the user) used to encrypt/decrypt function resources in key id format. If specified, you must also provide an artifact registry repository using the docker_repository field that was created with the same KMS crypto key."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name used for cloud function and associated resources."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
}

variable "repository_settings" {
  description = "Docker Registry to use for storing the function's Docker images and specific repository. If kms_key is provided, the repository must have already been encrypted with the key."
  type = object({
    registry   = optional(string)
    repository = optional(string)
  })
  default = {
    registry = "ARTIFACT_REGISTRY"
  }
}

variable "secrets" {
  description = "Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format."
  type = map(object({
    is_volume  = bool
    project_id = string
    secret     = string
    versions   = list(string)
  }))
  nullable = false
  default  = {}
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

variable "trigger_config" {
  description = "Function trigger configuration. Leave null for HTTP trigger."
  type = object({
    event    = string
    resource = string
    retry    = optional(bool)
  })
  default = null
}

variable "vpc_connector" {
  description = "VPC connector configuration. Set create to 'true' if a new connector needs to be created."
  type = object({
    create          = bool
    name            = string
    egress_settings = string
  })
  default = null
}

variable "vpc_connector_config" {
  description = "VPC connector network configuration. Must be provided if new VPC connector is being created."
  type = object({
    ip_cidr_range = string
    network       = string
  })
  default = null
}
