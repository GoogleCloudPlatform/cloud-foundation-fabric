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

variable "bundle_path" {
  description = "Path used to write the intermediate Cloud Function code bundle."
  type        = string
  default     = "./bundle.zip"
}

variable "cloud_function_config" {
  description = "Optional Cloud Function configuration."
  type = object({
    bucket_name          = optional(string)
    build_worker_pool_id = optional(string)
    bundle_path          = optional(string, "./bundle.zip")
    debug                = optional(bool, false)
    memory_mb            = optional(number, 256)
    source_dir           = optional(string, "../src")
    timeout_seconds      = optional(number, 540)
    version              = optional(string, "v1")
    vpc_connector = optional(object({
      name            = string
      egress_settings = optional(string, "ALL_TRAFFIC")
    }))
  })
  default  = {}
  nullable = false
}

variable "dashboard_json_path" {
  description = "Optional monitoring dashboard to deploy."
  type        = string
  default     = null
}

variable "discovery_config" {
  description = "Discovery configuration. Discovery root is the organization or a folder. If monitored folders and projects are empty, every project under the discovery root node will be monitored."
  type = object({
    discovery_root     = string
    monitored_folders  = list(string)
    monitored_projects = list(string)
    custom_quota_file  = optional(string)
  })
  nullable = false
  validation {
    condition = (
      var.discovery_config.monitored_folders != null &&
      var.discovery_config.monitored_projects != null
    )
    error_message = "Monitored folders and projects can be empty lists, but they cannot be null."
  }
}

variable "grant_discovery_iam_roles" {
  description = "Optionally grant required IAM roles to Cloud Function service account."
  type        = bool
  default     = false
  nullable    = false
}

variable "labels" {
  description = "Billing labels used for the Cloud Function, and the project if project_create is true."
  type        = map(string)
  default     = {}
}

variable "monitoring_project" {
  description = "Project where generated metrics will be written. Default is to use the same project where the Cloud Function is deployed."
  type        = string
  default     = null
}

variable "name" {
  description = "Name used to create Cloud Function related resources."
  type        = string
  default     = "net-dash"
}

variable "project_create_config" {
  description = "Optional configuration if project creation is required."
  type = object({
    billing_account_id = string
    parent_id          = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project id where the Cloud Function will be deployed."
  type        = string
}

variable "region" {
  description = "Compute region where the Cloud Function will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "schedule_config" {
  description = "Schedule timer configuration in crontab format."
  type        = string
  default     = "*/30 * * * *"
}
