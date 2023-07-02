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

variable "alert_configs" {
  description = "Configure creation of monitoring alerts for specific quotas. Keys match quota names."
  type = map(object({
    documentation = optional(string)
    enabled       = optional(bool)
    labels        = optional(map(string))
    threshold     = optional(number, 0.75)
  }))
  nullable = false
  default  = {}
  validation {
    condition     = alltrue([for k, v in var.alert_configs : v != null])
    error_message = "Set values as {} instead of null."
  }
}

variable "bundle_path" {
  description = "Path used to write the intermediate Cloud Function code bundle."
  type        = string
  default     = "./bundle.zip"
}

variable "name" {
  description = "Arbitrary string used to name created resources."
  type        = string
  default     = "quota-monitor"
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

variable "quota_config" {
  description = "Cloud function configuration."
  type = object({
    exclude = optional(list(string), [
      "a2", "c2", "c2d", "committed", "g2", "interconnect", "m1", "m2", "m3",
      "nvidia", "preemptible"
    ])
    include  = optional(list(string))
    projects = optional(list(string))
    regions  = optional(list(string))
    dry_run  = optional(bool, false)
    verbose  = optional(bool, false)
  })
  nullable = false
  default  = {}
}

variable "region" {
  description = "Compute region used in the example."
  type        = string
  default     = "europe-west1"
}

variable "schedule_config" {
  description = "Schedule timer configuration in crontab format."
  type        = string
  default     = "0 * * * *"
}
