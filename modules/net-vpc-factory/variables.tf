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
    locations   = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "data_defaults" {
  description = "Optional default values used when corresponding vpc data from files are missing."
  type = object({
    project_id                        = optional(string)
    description                       = optional(string, "Terraform managed")
    auto_create_subnetworks           = optional(bool)
    delete_default_routes_on_create   = optional(bool, true)
    mtu                               = optional(number)
    routing_mode                      = optional(string, "GLOBAL")
    firewall_policy_enforcement_order = optional(string, "AFTER_CLASSIC_FIREWALL")
    create_googleapis_routes = optional(object({
      directpath   = optional(bool)
      directpath-6 = optional(bool)
      private      = optional(bool)
      private-6    = optional(bool)
      restricted   = optional(bool)
      restricted-6 = optional(bool)
    }), {})
    dns_policy = optional(object({
      inbound = optional(bool)
      logging = optional(bool)
      outbound = optional(object({
        private_ns = optional(list(string))
        public_ns  = optional(list(string))
      }))
    }))
    ipv6_config = optional(object({
      enable_ula_internal = optional(bool)
      internal_range      = optional(string)
    }), {})
  })
  default  = {}
  nullable = false
}

variable "data_overrides" {
  description = "Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`."
  type = object({
    project_id                        = optional(string)
    description                       = optional(string)
    auto_create_subnetworks           = optional(bool)
    delete_default_routes_on_create   = optional(bool)
    mtu                               = optional(number)
    routing_mode                      = optional(string)
    firewall_policy_enforcement_order = optional(string)
    create_googleapis_routes = optional(object({
      directpath   = optional(bool)
      directpath-6 = optional(bool)
      private      = optional(bool)
      private-6    = optional(bool)
      restricted   = optional(bool)
      restricted-6 = optional(bool)
    }))
    dns_policy = optional(object({
      inbound = optional(bool)
      logging = optional(bool)
      outbound = optional(object({
        private_ns = optional(list(string))
        public_ns  = optional(list(string))
      }))
    }))
    ipv6_config = optional(object({
      enable_ula_internal = optional(bool)
      internal_range      = optional(string)
    }))
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    vpcs     = optional(string, "data")
    defaults = optional(string, "data/defaults.yaml")
  })
  default  = {}
  nullable = false
}
