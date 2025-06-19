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

variable "_testing" {
  description = "Populate this variable to avoid triggering the data source."
  type = object({
    name             = string
    number           = number
    services_enabled = optional(list(string), [])
  })
  default = null
}

variable "analytics_region" {
  description = "Region."
  type        = string
}

variable "instance_region" {
  description = "Region."
  type        = string
}

variable "network_config" {
  description = "Network configuration."
  type = object({
    subnet_ip_cidr_range            = string
    subnet_psc_ip_cidr_range        = string
    subnet_proxy_only_ip_cidr_range = string
  })
}

variable "project_id" {
  description = "Project ID."
  type        = string
}