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
  description = "Configuration of the auto-created helth check."
  type = object({
    type    = string      # http https tcp ssl http2
    check   = map(any)    # actual health check block attributes
    config  = map(number) # interval, thresholds, timeout
    logging = bool
  })
  default = {
    type = "http"
    check = {
      port_specification = "USE_SERVING_PORT"
    }
    config  = {}
    logging = false
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
