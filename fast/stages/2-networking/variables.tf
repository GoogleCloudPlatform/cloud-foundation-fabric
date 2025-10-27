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
    cidr_ranges_sets  = optional(map(list(string)), {})
    custom_roles      = optional(map(string), {})
    folder_ids        = optional(map(string), {})
    kms_keys          = optional(map(string), {})
    iam_principals    = optional(map(string), {})
    locations         = optional(map(string), {})
    project_ids       = optional(map(string), {})
    storage_buckets   = optional(map(string), {})
    tag_keys          = optional(map(string), {})
    tag_values        = optional(map(string), {})
    vpc_sc_perimeters = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    defaults              = optional(string, "datasets/hub-and-spokes-peerings/defaults.yaml")
    dns                   = optional(string, "datasets/hub-and-spokes-peerings/dns/zones")
    dns-response-policies = optional(string, "datasets/hub-and-spokes-peerings/dns/response-policies")
    firewall-policies     = optional(string, "datasets/hub-and-spokes-peerings/firewall-policies")
    folders               = optional(string, "datasets/hub-and-spokes-peerings/folders")
    ncc-hubs              = optional(string, "datasets/hub-and-spokes-peerings/ncc-hubs")
    nvas                  = optional(string, "datasets/hub-and-spokes-peerings/nvas")
    projects              = optional(string, "datasets/hub-and-spokes-peerings/projects")
    vpcs                  = optional(string, "datasets/hub-and-spokes-peerings/vpcs")
  })
  nullable = false
  default  = {}
}

variable "outputs_location" {
  description = "Path where tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "universe" {
  # tfdoc:variable:source 0-org-setup
  description = "GCP universe where to deploy projects. The prefix will be prepended to the project id."
  type = object({
    domain                         = string
    prefix                         = string
    forced_jit_service_identities  = optional(list(string), [])
    unavailable_services           = optional(list(string), [])
    unavailable_service_identities = optional(list(string), [])
  })
  default = null
}
