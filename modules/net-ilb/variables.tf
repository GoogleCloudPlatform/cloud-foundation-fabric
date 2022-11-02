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

variable "backend_config" {
  description = "Optional backend configuration."
  type = object({
    session_affinity                = string
    timeout_sec                     = number
    connection_draining_timeout_sec = number
  })
  default = null
}

variable "backends" {
  description = "Load balancer backends, balancing mode is one of 'CONNECTION' or 'UTILIZATION'."
  type = list(object({
    failover       = bool
    group          = string
    balancing_mode = string
  }))
}

variable "description" {
  description = "Optional description used for resources."
  type        = string
  default     = "Terraform managed."
}

variable "failover_config" {
  description = "Optional failover configuration."
  type = object({
    disable_connection_drain  = bool
    drop_traffic_if_unhealthy = bool
    ratio                     = number
  })
  default = null
}

variable "global_access" {
  description = "Global access, defaults to false if not set."
  type        = bool
  default     = null
}

variable "group_configs" {
  description = "Optional unmanaged groups to create. Can be referenced in backends via outputs."
  type = map(object({
    instances   = list(string)
    named_ports = map(number)
    zone        = string
  }))
  default = {}
}

variable "health_check" {
  description = "Name of existing health check to use, disables auto-created health check."
  type        = string
  default     = null
}

variable "health_check_config" {
  description = "Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage."
  type = object({
    check_interval_sec  = optional(number)
    description         = optional(string, "Terraform managed.")
    enable_logging      = optional(bool, false)
    healthy_threshold   = optional(number)
    timeout_sec         = optional(number)
    unhealthy_threshold = optional(number)
    grpc = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      service_name       = optional(string)
    }))
    http = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
      use_protocol       = optional(string, "http") # http http2 https
    }))
    tcp = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
      use_ssl            = optional(bool, false)
    }))
  })
  default = null
  validation {
    condition = (
      (try(var.health_check_config.grpc, null) == null ? 0 : 1) +
      (try(var.health_check_config.http, null) == null ? 0 : 1) +
      (try(var.health_check_config.tcp, null) == null ? 0 : 1) <= 1
    )
    error_message = "Only one health check type can be configured at a time."
  }
}

variable "labels" {
  description = "Labels set on resources."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name used for all resources."
  type        = string
}

variable "network" {
  description = "Network used for resources."
  type        = string
}

variable "ports" {
  description = "Comma-separated ports, leave null to use all ports."
  type        = list(string)
  default     = null
}

variable "project_id" {
  description = "Project id where resources will be created."
  type        = string
}

variable "protocol" {
  description = "IP protocol used, defaults to TCP."
  type        = string
  default     = "TCP"
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "service_label" {
  description = "Optional prefix of the fully qualified forwarding rule name."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Subnetwork used for the forwarding rule."
  type        = string
}
