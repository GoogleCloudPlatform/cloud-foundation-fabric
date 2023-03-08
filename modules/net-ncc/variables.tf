/**
 * Copyright 2023 Google LLC
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
  description = "Autonomous System Number for the CR. All spokes in a hub should use the same ASN."
  type        = number
}

variable "custom_advertise" {
  description = "IP ranges to advertise if not using default route advertisement (subnet ranges)."
  type = object({
    all_subnets = bool
    ip_ranges   = map(string) # map of descriptions and address ranges
  })
}

variable "data_transfer" {
  description = "Site-to-site data transfer feature, available only in some regions."
  type        = bool
}

variable "description" {
  description = "An optional description of the NCC hub."
  type        = string
  default     = "Terraform-managed."
}

variable "ip_intf1" {
  description = "IP address for the CR interface 1. It must belong to the primary range of the subnet."
  type        = string
}

variable "ip_intf2" {
  description = "IP address for the CR interface 2. It must belong to the primary range of the subnet."
  type        = string
}

variable "keepalive" {
  description = "The interval in seconds between BGP keepalive messages that are sent to the peer."
  type        = number
}

variable "name" {
  description = "The name of the NCC hub being created."
  type        = string
}

variable "peer_asn" {
  description = "Peer Autonomous System Number used by the router appliances."
  type        = number
}

variable "project_id" {
  description = "The ID of the project where the NCC hub & spokes will be created."
  type        = string
}

variable "ras" {
  description = "List of router appliances this spoke is associated with."
  type = list(object({
    vm = string # URI
    ip = string
  }))
}

variable "region" {
  description = "Region where the spoke is located."
  type        = string
}

variable "subnetwork" {
  description = "The URI of the subnetwork that CR interfaces belong to."
  type        = string
}

variable "vpc" {
  description = "A reference to the network to which the CR belongs."
  type        = string
}
