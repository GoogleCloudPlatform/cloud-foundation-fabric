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

variable "address" {
  description = "Optional IP address used for the forwarding rule."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description used for resources."
  type        = string
  default     = "Terraform managed."
}

variable "group_configs" {
  description = "Optional unmanaged groups to create. Can be referenced in backends via outputs."
  type = map(object({
    zone        = string
    instances   = optional(list(string), [])
    named_ports = optional(map(number), {})
  }))
  default  = {}
  nullable = false
}

variable "labels" {
  description = "Labels set on resources."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Load balancer name."
  type        = string
}

variable "network_tier_premium" {
  description = "Use premium network tier. Defaults to true."
  type        = bool
  default     = true
  nullable    = false
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "ports" {
  description = "Optional ports for HTTP load balancer, valid ports are 80 and 8080."
  type        = list(string)
  default     = null
}

variable "protocol" {
  description = "IP protocol used, defaults to TCP."
  type        = string
  default     = "HTTP"
  nullable    = false
}

variable "region" {
  description = "The region where to allocate the ILB resources."
  type        = string
}

variable "ssl_certificates" {
  description = "SSL target proxy certificates (only if protocol is HTTPS). Specify id for existing certificates, create config attributes to create."
  type = list(object({
    create_config = optional(object({
      domains              = list(string)
      name                 = list(string)
      tls_private_key      = string
      tls_self_signed_cert = string
    }))
    id = optional(string)
  }))
  default  = []
  nullable = false
}

variable "static_ip_config" {
  description = "Static IP address configuration."
  type = object({
    reserve = bool
    options = object({
      address    = string
      subnetwork = string # The subnet id
    })
  })
  default = {
    reserve = false
    options = null
  }
}

variable "vpc_config" {
  description = "VPC-level configuration."
  type = object({
    network    = string
    subnetwork = string
  })
  nullable = false
}
