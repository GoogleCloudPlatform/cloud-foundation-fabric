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
  description = "ASN for all CRs in the hub."
  type        = number
}

variable "description" {
  description = "An optional description of the NCC hub."
  type        = string
  default     = "Terraform-managed."
}

variable "name" {
  description = "The name of the NCC hub being created."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where the NCC hub & spokes will be created."
  type        = string
}

variable "spokes" {
  description = "List of NCC spokes."
  type = map(object({
    vpc        = string
    region     = string
    subnetwork = string # URI
    nvas = list(object({
      vm = string # URI
      ip = string
    }))
    router = object({
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string) # map of descriptions and address ranges
      }))
      ip1       = string
      ip2       = string
      keepalive = optional(number)
      peer_asn  = number
    })
  }))
}
