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
  description = "Optional unmanaged groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    zone        = string
    instances   = optional(list(string))
    named_ports = optional(map(number), {})
    project_id  = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "https_proxy_config" {
  description = "HTTPS proxy connfiguration."
  type = object({
    certificate_manager_certificates = optional(list(string))
    certificate_map                  = optional(string)
    quic_override                    = optional(string)
    ssl_policy                       = optional(string)
  })
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
    description = optional(string)
    cloudfunction = optional(object({
      region          = string
      target_function = optional(string)
      target_urlmask  = optional(string)
    }))
    cloudrun = optional(object({
      region = string
      target_service = optional(object({
        name = string
        tag  = optional(string)
      }))
      target_urlmask = optional(string)
    }))
    gce = optional(object({
      network    = string
      subnetwork = string
      zone       = string
      # default_port = optional(number)
      endpoints = optional(map(object({
        instance   = string
        ip_address = string
        port       = number
      })))
    }))
    hybrid = optional(object({
      network = string
      zone    = string
      # re-enable once provider properly support this
      # default_port = optional(number)
      endpoints = optional(map(object({
        ip_address = string
        port       = number
      })))
    }))
    psc = optional(object({
      region         = string
      target_service = string
      network        = optional(string)
      subnetwork     = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        (try(v.cloudfunction, null) == null ? 0 : 1) +
        (try(v.cloudrun, null) == null ? 0 : 1) +
        (try(v.gce, null) == null ? 0 : 1) +
        (try(v.hybrid, null) == null ? 0 : 1) +
        (try(v.psc, null) == null ? 0 : 1) == 1
      )
    ])
    error_message = "Only one type of NEG can be configured at a time."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.cloudrun == null
        ? true
        : v.cloudrun.target_urlmask != null || v.cloudrun.target_service != null
      )
    ])
    error_message = "Cloud Run NEGs need either target service or target urlmask defined."
  }
  validation {
    condition = alltrue([
      for k, v in var.neg_configs : (
        v.cloudfunction == null
        ? true
        : v.cloudfunction.target_urlmask != null || v.cloudfunction.target_function != null
      )
    ])
    error_message = "Cloud Function NEGs need either target function or target urlmask defined."
  }
}

variable "ports" {
  description = "Optional ports for HTTP load balancer, valid ports are 80 and 8080."
  type        = list(string)
  default     = null
}

variable "project_id" {
  description = "Project id."
  type        = string
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
  description = "Region where the load balancer is created."
  type        = string
}

variable "ssl_certificates" {
  description = "SSL target proxy certificates (only if protocol is HTTPS) for existing, custom, and managed certificates."
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


variable "vpc" {
  description = "VPC-level configuration."
  type        = string
  nullable    = false
}
