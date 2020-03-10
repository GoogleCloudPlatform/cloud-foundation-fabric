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

variable "coredns_config" {
  description = "CoreDNS configuration, set to null to use default."
  type        = string
  default     = null
}

variable "dns_domain" {
  description = "DNS domain used for on-prem host records."
  type        = string
  default     = "onprem.example.com"
}

variable "local_ip_cidr_range" {
  description = "IP CIDR range used for the Docker onprem network."
  type        = string
  default     = "192.168.192.0/24"
}

variable "machine_type" {
  description = "Machine type."
  type        = string
  default     = "g1-small"
}

variable "name" {
  description = "On-prem-in-a-box compute instance name."
  type        = string
  default     = "onprem"
}

variable "network" {
  description = "VPC network name."
  type        = string
}

variable "network_tags" {
  description = "Network tags."
  type        = list(string)
  default     = ["ssh"]
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "service_account" {
  description = "Service account customization."
  type = object({
    email  = string
    scopes = list(string)
  })
  default = {
    email = null
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
}

variable "subnet_self_link" {
  description = "VPC subnet self link."
  type        = string
}

variable "vpn_config" {
  description = "VPN configuration, type must be one of 'dynamic' or 'static'."
  type = object({
    peer_ip       = string
    shared_secret = string
    type          = string
  })
}

variable "vpn_dynamic_config" {
  description = "BGP configuration for dynamic VPN, ignored if VPN type is 'static'."
  type = object({
    local_bgp_asn     = number
    local_bgp_address = string
    peer_bgp_asn      = number
    peer_bgp_address  = string
  })
  default = {
    local_bgp_asn     = 65002
    local_bgp_address = "169.254.0.2"
    peer_bgp_asn      = 65001
    peer_bgp_address  = "169.254.0.1"
  }
}

variable "vpn_static_ranges" {
  description = "Remote CIDR ranges for static VPN, ignored if VPN type is 'dynamic'."
  type        = list(string)
  default     = []
}

variable "zone" {
  description = "Compute zone."
  type        = string
}
