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

variable "asn" {
  description = "Local BGP asn."
  type        = number
  default     = 64521
  nullable    = false
}

variable "external_address" {
  description = "Public address of the instance."
  type        = string
  nullable    = false
}

variable "ip_range" {
  description = "Local address range used for the Docker network and announced via BGP."
  type        = string
  default     = "192.168.128.0/24"
  nullable    = false
}

variable "peer_configs" {
  description = "Peer configurations."
  type = list(object({
    address       = string
    shared_secret = string
    bgp_session = optional(object({
      asn           = optional(number, 64520)
      local_address = optional(string)
      peer_address  = optional(string)
    }), {})
  }))
  nullable = false
}
