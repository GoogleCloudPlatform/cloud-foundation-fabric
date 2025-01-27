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

# tfdoc:file:description FAST stage interface.

variable "_fast_debug" {
  description = "Internal FAST variable used for testing and debugging. Do not use."
  type = object({
    skip_datasources = optional(bool, false)
  })
  nullable = false
  default  = {}
}

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "certificate_authority_pools" {
  # tfdoc:variable:source 2-security
  description = "Certificate authority pools."
  type = map(object({
    id       = string
    ca_ids   = map(string)
    location = string
  }))
  nullable = false
  default  = {}
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Networking stage host project id aliases."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "organization" {
  # tfdoc:variable:source 0-globals
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "vpc_self_links" {
  # tfdoc:variable:source 2-networking
  description = "VPC network self links."
  type        = map(string)
  nullable    = false
  default     = {}
}

