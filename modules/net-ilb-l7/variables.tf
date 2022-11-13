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

variable "backend_service_config" {
  description = "Backend service level configuration."
  type = map(object({
    affinity_cookie_ttl_sec         = optional(number)
    connection_draining_timeout_sec = optional(number)
    health_checks                   = optional(list(string), ["default"])
    locality_lb_policy              = optional(string)
    log_sample_rate                 = optional(number)
    port_name                       = optional(string)
    session_affinity                = optional(string)
    timeout_sec                     = optional(number)
    circuit_breakers = optional(object({
      max_connections             = optional(number)
      max_pending_requests        = optional(number)
      max_requests                = optional(number)
      max_requests_per_connection = optional(number)
      max_retries                 = optional(number)
      connect_timeout = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
    }))
    connection_tracking = optional(object({
      idle_timeout_sec          = optional(number)
      persist_conn_on_unhealthy = optional(string)
      track_per_session         = optional(bool)
    }))
    consistent_hash = optional(object({
      http_header_name  = optional(string)
      minimum_ring_size = optional(number)
      http_cookie = optional(object({
        name = optional(string)
        path = optional(string)
        ttl = optional(object({
          seconds = number
          nanos   = optional(number)
        }))
      }))
    }))
    enable_subsetting = optional(bool)
    failover_config = optional(object({
      disable_conn_drain        = optional(bool)
      drop_traffic_if_unhealthy = optional(bool)
      ratio                     = optional(number)
    }))
    iap_config = optional(object({
      oauth2_client_id            = string
      oauth2_client_secret        = string
      oauth2_client_secret_sha256 = optional(string)
    }))
    outlier_detection = optional(object({
      consecutive_errors                    = optional(number)
      consecutive_gateway_failure           = optional(number)
      enforcing_consecutive_errors          = optional(number)
      enforcing_consecutive_gateway_failure = optional(number)
      enforcing_success_rate                = optional(number)
      max_ejection_percent                  = optional(number)
      success_rate_minimum_hosts            = optional(number)
      success_rate_request_volume           = optional(number)
      success_rate_stdev_factor             = optional(number)
      base_ejection_time = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      interval = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = contains(
      [
        "-", "ROUND_ROBIN", "LEAST_REQUEST", "RING_HASH",
        "RANDOM", "ORIGINAL_DESTINATION", "MAGLEV"
      ],
      try(var.backend_service_config.locality_lb_policy, "-")
    )
    error_message = "Invalid locality lb policy value."
  }
  validation {
    condition = contains(
      [
        "NONE", "CLIENT_IP", "CLIENT_IP_NO_DESTINATION",
        "CLIENT_IP_PORT_PROTO", "CLIENT_IP_PROTO"
      ],
      try(var.backend_service_config.session_affinity, "NONE")
    )
    error_message = "Invalid session affinity value."
  }
}

variable "backends" {
  description = "Load balancer backends, balancing mode is one of 'CONNECTION', 'RATE' or 'UTILIZATION'."
  type = list(object({
    group           = string
    balancing_mode  = optional(string, "CONNECTION")
    capacity_scaler = optional(number)
    description     = optional(string, "Terraform managed.")
    failover        = optional(bool, false)
    max_connections = optional(object({
      per_endpoint = optional(number)
      per_group    = optional(number)
      per_instance = optional(number)
    }))
    max_rate = optional(object({
      per_endpoint = optional(number)
      per_group    = optional(number)
      per_instance = optional(number)
    }))
    max_utilization = optional(number)
  }))
  default  = []
  nullable = false
  validation {
    condition = alltrue([
      for b in var.backends : contains(
        ["CONNECTION", "RATE", "UTILIZATION"],
        coalesce(b.balancing_mode, "CONNECTION")
    )])
    error_message = "When specified balancing mode needs to be 'CONNECTION', 'RATE' or 'UTILIZATION'."
  }
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
