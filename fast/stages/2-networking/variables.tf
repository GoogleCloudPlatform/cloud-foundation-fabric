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
    email_addresses   = optional(map(string), {})
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
    dataset = optional(string, "datasets/hub-and-spokes-peerings")
    paths = optional(object({
      defaults              = optional(string, "defaults.yaml")
      dns                   = optional(string, "dns/zones")
      dns_response_policies = optional(string, "dns/response-policies")
      firewall_policies     = optional(string, "firewall-policies")
      folders               = optional(string, "folders")
      ncc_hubs              = optional(string, "ncc-hubs")
      nvas                  = optional(string, "nvas")
      projects              = optional(string, "projects")
      vpcs                  = optional(string, "vpcs")
    }), {})
  })
  nullable = false
  default  = {}
}

