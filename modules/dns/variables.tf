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

variable "description" {
  description = "Domain description."
  type        = string
  default     = "Terraform managed."
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = null
}

variable "name" {
  description = "Zone name, must be unique within the project."
  type        = string
}

variable "project_id" {
  description = "Project id for the zone."
  type        = string
}

variable "recordsets" {
  description = "Map of DNS recordsets in \"type name\" => {ttl, [records]} format."
  type = map(object({
    ttl     = optional(number, 300)
    records = optional(list(string))
    geo_routing = optional(list(object({
      location = string
      records  = list(string)
    })))
    wrr_routing = optional(list(object({
      weight  = number
      records = list(string)
    })))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in coalesce(var.recordsets, {}) :
      length(split(" ", k)) == 2
    ])
    error_message = "Recordsets must have keys in the format \"type name\"."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.recordsets, {}) : (
        (v.records != null && v.wrr_routing == null && v.geo_routing == null) ||
        (v.records == null && v.wrr_routing != null && v.geo_routing == null) ||
        (v.records == null && v.wrr_routing == null && v.geo_routing != null)
      )
    ])
    error_message = "Only one of records, wrr_routing or geo_routing can be defined for each recordset."
  }
}

variable "zone_config" {
  description = "DNS zone configuration."
  type = object({
    domain = string
    forwarding = optional(object({
      forwarders      = optional(map(string))
      client_networks = list(string)
    }))
    peering = optional(object({
      client_networks = list(string)
      peer_network    = string
    }))
    public = optional(object({
      dnssec_config = optional(object({
        non_existence = optional(string, "nsec3")
        state         = string
        key_signing_key = optional(object(
          { algorithm = string, key_length = number }),
          { algorithm = "rsasha256", key_length = 2048 }
        )
        zone_signing_key = optional(object(
          { algorithm = string, key_length = number }),
          { algorithm = "rsasha256", key_length = 1024 }
        )
      }))
      enable_logging = optional(bool, false)
    }))
    private = optional(object({
      client_networks             = list(string)
      service_directory_namespace = optional(string)
    }))
  })
  validation {
    condition = (
      (try(var.zone_config.forwarding, null) == null ? 0 : 1) +
      (try(var.zone_config.peering, null) == null ? 0 : 1) +
      (try(var.zone_config.public, null) == null ? 0 : 1) +
      (try(var.zone_config.private, null) == null ? 0 : 1) <= 1
    )
    error_message = "Only one type of zone can be configured at a time."
  }
  default = null
}


