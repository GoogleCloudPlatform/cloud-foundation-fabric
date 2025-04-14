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

variable "anonymization_scheduler" {
  description = "Schedule for triggering export, anonymization and import of data."
  type = object({
    trigger-export = string
    anonymize-data = string
    import-data    = string
  })
  default = {
    trigger-export = "0 8 29 2 *"
    anonymize-data = "0 12 29 2 *"
    import-data    = "0 13 29 2 *"
  }
}

variable "cloud_function_config" {
  description = "Optional Cloud Function configuration."
  type = object({
    build_worker_pool_id = optional(string)
    build_sa             = optional(string)
    debug                = optional(bool, false)
    cpu                  = optional(number, 1)
    memory_mb            = optional(number, 2048)
    timeout_seconds      = optional(number, 3600)
    vpc_connector = optional(object({
      name            = string
      egress_settings = optional(string, "ALL_TRAFFIC")
    }))
  })
  default  = {}
  nullable = false
}

variable "dlp_config" {
  description = "Data Loss prevention configuration."
  type = object({
    region                 = string
    deidentify_template_id = string
    inspect_template_id    = string
  })
  default = null
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  nullable    = false
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_create_config" {
  description = "Create project instead of using an existing one."
  type = object({
    billing_account = string
    parent          = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project id that references existing project."
  type        = string
}

variable "regions" {
  description = "Regions: primary for all resources and secondary for clouds scheduler since the latter is available in few regions."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "europe-west1"
    secondary = "europe-west1"
  }
}

variable "secops_config" {
  description = "SecOps config."
  type = object({
    region = string
    source_tenant = object({
      customer_id = string
      gcp_project = string
    })
    target_tenant = object({
      gcp_project  = string
      customer_id  = string
      forwarder_id = string
    })
  })
}

variable "skip_anonymization" {
  description = "Whether to skip anonymization step and just import data exported from source tenant."
  type        = bool
  default     = false
}
