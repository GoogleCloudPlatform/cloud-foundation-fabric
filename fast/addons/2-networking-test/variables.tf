/**
 * Copyright 2024 Google LLC
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

variable "factories_config" {
  description = "Configuration for the resource factories."
  type = object({
    instances        = optional(string, "data/instances")
    service_accounts = optional(string, "data/service-accounts")
  })
  nullable = false
  default  = {}
}

variable "name" {
  description = "Prefix used for all resource names."
  type        = string
  nullable    = true
  default     = "test"
}

variable "test_instances" {
  description = "Test instances to be created."
  type = map(object({
    project_id      = string
    network_id      = string
    service_account = string
    subnet_id       = string
    image           = optional(string)
    metadata        = optional(map(string), {})
    tags            = optional(list(string), ["ssh"])
    type            = optional(string, "e2-micro")
    user_data_file  = optional(string)
    zones           = optional(list(string), ["b"])
  }))
  nullable = false
  default  = {}
}

variable "test_service_accounts" {
  description = "Service accounts used by instances."
  type = map(object({
    project_id        = string
    display_name      = optional(string)
    iam_project_roles = optional(map(list(string)), {})
  }))
  nullable = false
  default  = {}
}
