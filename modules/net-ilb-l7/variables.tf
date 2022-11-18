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

# during the preview phase you cannot change this attribute on an existing rule
variable "global_access" {
  description = "Allow client access from all regions."
  type        = bool
  default     = null
}

variable "group_configs" {
  description = "Optional unmanaged groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    zone        = string
    instances   = optional(list(string), [])
    named_ports = optional(map(number), {})
    project_id  = optional(string)
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

variable "neg_configs" {
  description = "Optional network endpoint groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    project_id = optional(string)
    cloudrun = optional(object({
      region = string
      target_service = optional(object({
        name = string
        tag  = optional(string)
      }))
      target_urlmask = optional(string)
    }))
    gce = optional(object({
      zone = string
      # default_port = optional(number)
      network    = optional(string)
      subnetwork = optional(string)
      endpoints = optional(list(object({
        instance   = string
        ip_address = string
        port       = number
      })))

    }))
    hybrid = optional(object({
      zone    = string
      network = optional(string)
      # re-enable once provider properly support this
      # default_port = optional(number)
      endpoints = optional(list(object({
        ip_address = string
        port       = number
      })))
    }))
    # psc = optional(object({}))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        (try(v.cloudrun, null) == null ? 0 : 1) +
        (try(v.gce, null) == null ? 0 : 1) +
        (try(v.hybrid, null) == null ? 0 : 1) == 1
      )
    ])
    error_message = "Only one type of neg can be configured at a time."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.cloudrun == null
        ? true
        : v.cloudrun.target_urlmask != null || v.cloudrun.target_service != null
      )
    ])
    error_message = "Cloud Run negs need either target type or target urlmask defined."
  }
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
  description = "Protocol supported by this load balancer."
  type        = string
  default     = "HTTP"
  nullable    = false
  validation {
    condition = (
      var.protocol == null || var.protocol == "HTTP" || var.protocol == "HTTPS"
    )
    error_message = "Protocol must be HTTP or HTTPS"
  }
}

variable "region" {
  description = "The region where to allocate the ILB resources."
  type        = string
}

variable "service_directory_registration" {
  description = "Service directory namespace and service used to register this load balancer."
  type = object({
    namespace = string
    service   = string
  })
  default = null
}

variable "ssl_certificates" {
  description = "SSL target proxy certificates (only if protocol is HTTPS)."
  type = object({
    certificate_ids = optional(list(string), [])
    create_configs = optional(map(object({
      certificate = string
      private_key = string
    })), {})
  })
  default  = {}
  nullable = false
}

variable "vpc_config" {
  description = "VPC-level configuration."
  type = object({
    network    = string
    subnetwork = string
  })
  nullable = false
}
