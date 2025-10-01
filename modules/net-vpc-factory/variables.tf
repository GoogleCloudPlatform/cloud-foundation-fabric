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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars        = optional(map(map(string)), {})
    custom_roles          = optional(map(string), {})
    folder_ids            = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    locations             = optional(object({
      bigquery = optional(string)
      logging  = optional(string)
      pubsub   = optional(list(string))
      storage  = optional(string)
    }), {})
    kms_keys              = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids           = optional(map(string), {})
    vpc_ids               = optional(map(string), {})
    vpc_subnet_ids               = optional(map(string), {})
    vpc_router_ids            = optional(map(string), {})
    service_account_ids   = optional(map(string), {})
    tag_keys              = optional(map(string), {})
    tag_values            = optional(map(string), {})
    vpc_host_projects     = optional(map(string), {})
    vpc_sc_perimeters     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "data_defaults" {
  description = "Optional default values used when corresponding network data from files are missing."
  type = object({
  })
  nullable = false
  default  = {}
}

variable "data_merges" {
  description = "Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`."
  type = object({
  })
  nullable = false
  default  = {}
}

variable "data_overrides" {
  description = "Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`."
  type = object({})
    # data overrides default to null to mark that they should not override
  nullable = false
  default  = {}
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    vpcs = string
  })
  nullable = false
}
