/**
 * Copyright 2021 Google LLC
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

variable "router" {
  description = "Router name and description. "
  type = object({
    name        = string
    description = string
    asn         = number
  })
  default = {
    name        = ""
    description = ""
    asn         =null
  }
}

variable "region" {
  description = "Region where the router resides"
  type        = string
  default     = "europe-west1-b"
}

variable "project_id" {
  description = "The project containing the resources"
  type        = string
}

variable "router_advertise_config" {
  description = "Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions."
  type = object({
    groups    = list(string)
    ip_ranges = map(string)
    mode      = string

  })
  default = null
}

variable "router_create" {
  description = "Create router."
  type        = bool
  default     = true
}

variable "network_name" {
  description = "A reference to the network to which this router belongs"
  type        = string
}

variable "description" {
  description = "Vlan attachement description"
  type        = string
  default     = ""
}

variable "vlan_attachment" {
  description = "VLAN attachment parameters"
  type = object({
    name          = string
    vlan_id       = number
    bandwidth     = string
    admin_enabled = bool
    interconnect  = string
  })
  default = {
    name          = ""
    vlan_id       = null
    bandwidth     = "BPS_10G"
    admin_enabled = true
    interconnect  = null
  }
}

variable "bgp" {
  description = "Bgp session parameters"
  type = object({
    peer_ip_address           = string
    peer_asn                  = number
    bgp_session_range         = string
    candidate_ip_ranges       = list(string)
    advertised_route_priority = number
  })
}




