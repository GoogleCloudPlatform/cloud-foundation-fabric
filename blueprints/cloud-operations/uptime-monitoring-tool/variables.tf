/**
 * Copyright 2023 Google LLC
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

variable "agent_config" {
  description = "Uptime monitoring agent script configuration."
  type = object({
    identifier = optional(string, "uptime-mon-agent")
    interval   = optional(number, 10)
    target_endpoints = optional(map(string), {
      "8.8.8.8" = "53"
    })
    timeout = optional(number, 10)
  })
  nullable = false
  default  = {}
}

variable "agent_project_id" {
  description = "GCP project the agent is provisioned to."
  type        = string
}

variable "alert_config" {
  description = "Configure creation of monitoring alert."
  type = object({
    enabled            = optional(bool, false)
    notification_email = optional(string)
  })
  nullable = false
  default  = {}
  validation {
    condition     = (!var.alert_config.enabled || (var.alert_config.enabled && var.alert_config.notification_email != null))
    error_message = "Notification email is mandatory if alert is enabled."
  }
}

variable "bootstrap_monitoring" {
  description = "Whether to create network dashboard, time series."
  type        = bool
  default     = false
}

variable "cidrs" {
  description = "CIDR ranges for subnets."
  type        = map(string)
  default = {
    agent = "10.0.0.0/24"
  }
}

variable "monitoring_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "nat_logging" {
  description = "Enables Cloud NAT logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'."
  type        = string
  default     = "ERRORS_ONLY"
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

variable "project_create" {
  description = "Create project instead of using an existing one."
  type        = bool
  default     = false
}

variable "region" {
  description = "GCP Region."
  type        = string
  default     = "europe-west8"
}

variable "uptime_mon_agent_vm_config" {
  description = "Network Monitoring agent VM configuration."
  type = object({
    instance_type = optional(string, "e2-standard-2")
    name          = optional(string, "uptime-mon-agent")
    network_tags  = optional(list(string), [])
    private_ip    = optional(string, null)
    public_ip     = optional(bool, false)
  })
  nullable = false
  default  = {}
}

variable "vpc_config" {
  description = "VPC Network and subnetwork self links for internal LB setup."
  type = object({
    network    = string
    subnetwork = string
  })
  default = null
}
