/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  type        = string
  description = "Project id."
}

variable "name" {
  type        = string
  description = "On-prem-in-a-box compute instance name."
  default     = "on-prem-in-a-box"
}

variable "zone" {
  type        = string
  description = "Compute zone."
}

variable "network" {
  type        = string
  description = "VPC network name. "
}

variable "subnet_self_link" {
  type        = string
  description = "VPC subnet self link."
}

variable "machine_type" {
  type        = string
  description = "Machine type."
  default     = "g1-small"
}

variable "network_tags" {
  type        = list(string)
  description = "Network tags."
  default     = ["ssh"]
}

variable "vpn_gateway_type" {
  type        = string
  description = "VPN Gateway type, applicable values are `static` and `dynamic`."
}


variable "peer_ip" {
  type        = string
  description = "IP Address of Cloud VPN Gateway."
}

variable "peer_bgp_session_range" {
  type        = string
  description = "Peer BGP sesison range of the BGP interface. Should be provided if `vpn_gateway_type` is `dynamic`"
  default     = "169.254.0.1/30"
}

variable "local_bgp_session_range" {
  type        = string
  description = "Local BGP sesison range of the BGP interface. Should be provided if `vpn_gateway_type` is `dynamic`"
  default     = "169.254.0.2/30"
}

variable "peer_bgp_asn" {
  type        = string
  description = "Peer BGP ASN. Should be provided if `vpn_gateway_type` is `dynamic`"
  default     = "65001"
}

variable "local_bgp_asn" {
  type        = string
  description = "Local BGP ASN. Should be provided if `vpn_gateway_type` is `dynamic`"
  default     = "65002"
}

variable "local_ip_cidr_range" {
  type    = string
  default = "192.168.192.0/24"
}

variable "remote_ip_cidr_ranges" {
  description = "List of comma separated remote CIDR ranges. Should be provided if `vpn_gateway_type` is `static`"
  type        = string
  default     = ""
}

variable "shared_secret" {
  type    = string
}
