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

variable "backend_service_config" {
  description = "Backend service level configuration."
  type = object({
    connection_draining_timeout_sec = optional(number)
    connection_tracking = optional(object({
      idle_timeout_sec          = optional(number)
      persist_conn_on_unhealthy = optional(string)
      track_per_session         = optional(bool)
    }))
    failover_config = optional(object({
      disable_conn_drain        = optional(bool)
      drop_traffic_if_unhealthy = optional(bool)
      ratio                     = optional(number)
    }))
    locality_lb_policy = optional(string)
    log_sample_rate    = optional(number)
    port_name          = optional(string)
    protocol           = optional(string, "UNSPECIFIED")
    session_affinity   = optional(string)
    timeout_sec        = optional(number)
  })
  default  = {}
  nullable = false
  validation {
    condition = contains(
      ["TCP", "UDP", "UNSPECIFIED"],
      coalesce(var.backend_service_config.protocol, "TCP")
    )
    error_message = "Protocol can be 'TCP', 'UDP', 'UNSPECIFIED'."
  }
  validation {
    condition = contains(
      ["MAGLEV", "WEIGHTED_MAGLEV"],
      coalesce(var.backend_service_config.locality_lb_policy, "MAGLEV")
    )
    error_message = "Locality LB policy can be 'MAGLEV', 'WEIGHTED_MAGLEV'."
  }
  validation {
    condition = contains(
      [
        "NONE", "CLIENT_IP", "CLIENT_IP_NO_DESTINATION",
        "CLIENT_IP_PORT_PROTO", "CLIENT_IP_PROTO"
      ],
      coalesce(var.backend_service_config.session_affinity, "NONE")
    )
    error_message = "Invalid session affinity value."
  }
}

variable "backends" {
  description = "Load balancer backends, balancing mode is one of 'CONNECTION' or 'UTILIZATION'."
  type = list(object({
    group       = string
    description = optional(string, "Terraform managed.")
    failover    = optional(bool, false)
  }))
  default  = []
  nullable = false
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
    instances   = optional(list(string))
    named_ports = optional(map(number), {})
  }))
  default  = {}
  nullable = false
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
    }))
    http2 = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    https = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    tcp = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
    }))
    ssl = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
    }))
  })
  default = {
    tcp = {
      port_specification = "USE_SERVING_PORT"
    }
  }
  validation {
    condition = (
      (try(var.health_check_config.grpc, null) == null ? 0 : 1) +
      (try(var.health_check_config.http, null) == null ? 0 : 1) +
      (try(var.health_check_config.http2, null) == null ? 0 : 1) +
      (try(var.health_check_config.https, null) == null ? 0 : 1) +
      (try(var.health_check_config.tcp, null) == null ? 0 : 1) +
      (try(var.health_check_config.ssl, null) == null ? 0 : 1) <= 1
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
  description = "IP protocol used, defaults to TCP. UDP or L3_DEFAULT can also be used."
  type        = string
  default     = "TCP"
  nullable    = false
  validation {
    condition     = contains(["L3_DEFAULT", "TCP", "UDP"], var.protocol)
    error_message = "Allowed values are 'TCP', 'UDP', 'L3_DEFAULT'."
  }
}

variable "region" {
  description = "GCP region."
  type        = string
}
