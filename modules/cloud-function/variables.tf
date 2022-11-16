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
    location                  = optional(string)
    lifecycle_delete_age_days = optional(number)
  })
  default = null
}

variable "bucket_name" {
  description = "Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null."
  type        = string
}

variable "build_worker_pool" {
  description = "Build worker pool, in projects/<PROJECT-ID>/locations/<REGION>/workerPools/<POOL_NAME> format"
  type        = string
  default     = null
}

variable "bundle_config" {
  description = "Cloud function source folder and generated zip bundle paths. Output path defaults to '/tmp/bundle.zip' if null."
  type = object({
    source_dir  = string
    output_path = optional(string, "/tmp/bundle.zip")
    excludes    = optional(list(string))
  })
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
  description = "Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout"
  type = object({
    entry_point     = optional(string, "main")
    instance_count  = optional(number, 1)
    memory_mb       = optional(number, 256) # Memory in MB
    runtime         = optional(string, "python310")
    timeout_seconds = optional(number, 180)
  })
  default = {
    entry_point     = "main"
    instance_count  = 1
    memory_mb       = 256
    runtime         = "python310"
    timeout_seconds = 180
  }
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
  default     = "europe-west1"
}

variable "secrets" {
  description = "Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format."
  type = map(object({
    is_volume  = bool
    project_id = number
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
    v1 = optional(object({
      event    = string
      resource = string
      retry    = optional(bool)
    })),
    v2 = optional(object({
      region       = optional(string)
      event_type   = optional(string)
      pubsub_topic = optional(string)
      event_filters = optional(list(object({
        attribute = string
        value     = string
        operator  = string
      })))
      service_account_email  = optional(string)
      service_account_create = optional(bool)
      retry_policy           = optional(string)
    }))
  })
  default = { v1 = null, v2 = null }
  validation {
    condition     = !(var.trigger_config.v1 != null && var.trigger_config.v2 != null)
    error_message = "Provide configuration for only one generation - either v1 or v2"
  }
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

variable "v2" {
  description = "Whether to use Cloud Function version 2nd Gen or 1st Gen."
  type        = bool
  default     = false
}


