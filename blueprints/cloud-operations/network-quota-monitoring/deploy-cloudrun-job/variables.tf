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

variable "dashboard_json_path" {
  description = "Optional monitoring dashboard to deploy."
  type        = string
  default     = null
}

variable "discovery_config" {
  description = "Discovery configuration. Discovery root is the organization or a folder. If monitored folders and projects are empty, every project under the discovery root node will be monitored."
  type = object({
    discovery_root     = string
    monitored_folders  = optional(list(string), [])
    monitored_projects = optional(list(string), [])
    # custom_quota_file  = optional(string)
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
  description = "Optionally grant required IAM roles to the monitoring tool service account."
  type        = bool
  default     = false
  nullable    = false
}

variable "monitoring_project" {
  description = "Project where generated metrics will be written. Default is to use the same project where the Cloud Function is deployed."
  type        = string
  default     = null
}

variable "name" {
  description = "Name used to create resources."
  type        = string
  default     = "netmon"
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
  description = "Project id where the tool will be deployed."
  type        = string
}

variable "region" {
  description = "Compute region where Cloud Run will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "schedule_config" {
  description = "Scheduler configuration. Region is only used if different from the one used for Cloud Run."
  type = object({
    crontab = optional(string, "*/30 * * * *")
    region  = optional(string)
  })
  default = {}
}
