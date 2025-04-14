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

variable "build_service_account" {
  description = "Build service account email."
  type        = string
  default     = null
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

variable "deletion_protection" {
  description = "Deletion protection setting for this Cloud Run service."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description."
  type        = string
  default     = "Terraform managed."
}

variable "encryption_key" {
  description = "The full resource name of the Cloud KMS CryptoKey."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Cloud function environment variables."
  type        = map(string)
  default = {
    LOG_EXECUTION_ID = "true"
  }
}

variable "eventarc_triggers" {
  description = "Event arc triggers for different sources."
  type = object({
    audit_log = optional(map(object({
      method  = string
      service = string
    })))
    pubsub                 = optional(map(string))
    service_account_email  = optional(string)
    service_account_create = optional(bool, false)
  })
  default = {}
  validation {
    condition     = var.eventarc_triggers.audit_log == null || (var.eventarc_triggers.audit_log != null && (var.eventarc_triggers.service_account_email != null || var.eventarc_triggers.service_account_create))
    error_message = "When setting var.eventarc_triggers.audit_log provide either service_account_email or set service_account_create to true"
  }
}

variable "function_config" {
  description = "Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout."
  type = object({
    entry_point        = optional(string, "main")
    max_instance_count = optional(number, 1)
    memory             = optional(string, "512Mi")
    cpu                = optional(string, "1")
    runtime            = optional(string, "python312")
    timeout            = optional(string, "180s")
  })
  default = {
    entry_point    = "main"
    instance_count = 1
    memory         = "512Mi"
    cpu            = "1"
    runtime        = "python312"
    timeout        = "180s"
  }
}

variable "iam" {
  description = "IAM bindings for topic in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "image_uri" {
  description = "The Cloud Run image URI."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "ingress" {
  description = "Ingress settings."
  type        = string
  default     = null
  validation {
    condition = (
      var.ingress == null ? true : contains(
        ["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    )
    error_message = <<EOF
    Ingress should be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY,
    INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
    EOF
  }
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

variable "secrets" {
  description = "Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format."
  type = map(object({
    is_volume = bool
    secret    = string
    version   = optional(string, "latest")
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

variable "tag_bindings" {
  description = "Tag bindings for this service, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "volume_mounts" {
  description = "The volume mounts."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = map(object({
    secret = optional(object({
      name         = string
      default_mode = optional(string)
      path         = optional(string)
      version      = optional(string)
      mode         = optional(string)
    }))
    cloud_sql_instances = optional(list(string))
    empty_dir_size      = optional(string)
    gcs = optional(object({
      # needs revision.gen2_execution_environment
      bucket       = string
      is_read_only = optional(bool)
    }))
    nfs = optional(object({
      server       = string
      path         = optional(string)
      is_read_only = optional(bool)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.volumes :
      sum([for kk, vv in v : vv == null ? 0 : 1]) == 1
    ])
    error_message = "Only one type of volume can be defined at a time."
  }
}

variable "vpc_access" {
  description = "VPC connector configuration. Set create to 'true' if a new connector needs to be created."
  type = object({
    connector = optional(string)
    egress    = optional(string, "ALL_TRAFFIC")
    network   = optional(string)
    subnet    = optional(string)
    tags      = optional(list(string))
  })
  nullable = false
  default  = {}
}

variable "vpc_connector_config" {
  description = "VPC connector network configuration. Must be provided if new VPC connector is being created."
  type = object({
    ip_cidr_range = string
    network       = string
    instances = optional(object({
      max = optional(number)
      min = optional(number, 2)
    }))
    throughput = optional(object({
      max = optional(number, 300)
      min = optional(number, 200)
    }))
  })
  default = null
  validation {
    condition = (
      var.vpc_connector_config == null ||
      try(var.vpc_connector_config.instances, null) != null ||
      try(var.vpc_connector_config.throughput, null) != null
    )
    error_message = "VPC connector must specify either instances or throughput."
  }
}
