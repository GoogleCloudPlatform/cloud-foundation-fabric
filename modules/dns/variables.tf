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

###############################################################################
#                                zone variables                               #
###############################################################################

variable "client_networks" {
  description = "List of VPC self links that can see this zone."
  type        = list(string)
  default     = []
}

variable "default_key_specs_key" {
  description = "DNSSEC default key signing specifications: algorithm, key_length, key_type, kind."
  type        = any
  default     = {}
}

variable "default_key_specs_zone" {
  description = "DNSSEC default zone signing specifications: algorithm, key_length, key_type, kind."
  type        = any
  default     = {}
}

variable "description" {
  description = "Domain description."
  type        = string
  default     = "Terraform managed."
}

variable "dnssec_config" {
  description = "DNSSEC configuration: kind, non_existence, state."
  type        = any
  default     = {}
}

variable "domain" {
  description = "Zone domain, must end with a period."
  type        = string
}

variable "forwarders" {
  description = "Map of {IPV4_ADDRESS => FORWARDING_PATH} for 'forwarding' zone types. Path can be 'default', 'private', or null for provider default."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Zone name, must be unique within the project."
  type        = string
}

variable "peer_network" {
  description = "Peering network self link, only valid for 'peering' zone types."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project id for the zone."
  type        = string
}

variable "recordsets" {
  description = "Map of DNS recordsets in \"type name\" => {ttl, [records]} format."
  type = map(object({
    ttl     = number
    records = list(string)
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.recordsets == null ? {} : var.recordsets :
      length(split(" ", k)) == 2
    ])
    error_message = "Recordsets must have keys in the format \"type name\"."
  }
}

variable "service_directory_namespace" {
  description = "Service directory namespace id (URL), only valid for 'service-directory' zone types."
  type        = string
  default     = null
}

variable "type" {
  description = "Type of zone to create, valid values are 'public', 'private', 'forwarding', 'peering', 'service-directory'."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "forwarding", "peering", "service-directory"], var.type)
    error_message = "Zone must be one of 'public', 'private', 'forwarding', 'peering', 'service-directory'."
  }
}

variable "zone_create" {
  description = "Create zone. When set to false, uses a data source to reference existing zone."
  type        = bool
  default     = true
}



