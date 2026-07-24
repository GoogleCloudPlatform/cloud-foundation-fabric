/**
 * Copyright 2026 Google LLC
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

variable "addresses" {
  description = "Optional IP addresses used for the forwarding rules, mapped by subnetwork key."
  type        = map(string)
  default     = null
}

variable "backend_service_configs" {
  description = "Backend service level configurations, keyed by name."
  type = map(object({
    name                            = optional(string)
    description                     = optional(string, "Terraform managed.")
    affinity_cookie_ttl_sec         = optional(number)
    connection_draining_timeout_sec = optional(number)
    health_checks                   = optional(list(string), ["default"])
    log_config = optional(object({
      enable          = optional(bool)
      sample_rate     = optional(number)
      optional_mode   = optional(string)
      optional_fields = optional(list(string))
    }))
    port_name  = optional(string)
    project_id = optional(string)
    service_lb_policy_config = optional(object({
      enable                    = optional(bool)
      load_balancing_algorithm  = optional(string, "WATERFALL_BY_REGION")
      auto_capacity_drain       = optional(bool)
      failover_health_threshold = optional(number)
    }))
    session_affinity = optional(string, "NONE")
    timeout_sec      = optional(number)
    backends = optional(list(object({
      group           = string
      balancing_mode  = optional(string, "CONNECTION")
      capacity_scaler = optional(number, 1)
      description     = optional(string, "Terraform managed.")
      max_connections = optional(object({
        per_endpoint = optional(number)
        per_group    = optional(number)
        per_instance = optional(number)
      }))
      max_utilization = optional(number)
    })))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.backend_service_configs :
      contains(["NONE", "CLIENT_IP"], v.session_affinity)
    ])
    error_message = "Invalid session affinity value."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.backend_service_configs : [
        for b in coalesce(v.backends, []) : contains(
          ["CONNECTION", "UTILIZATION"], coalesce(b.balancing_mode, "CONNECTION")
        )
      ]
    ]))
    error_message = "When specified, balancing mode needs to be 'CONNECTION' or 'UTILIZATION'."
  }
  validation {
    condition = alltrue([
      for k, v in var.backend_service_configs : (
        try(v.service_lb_policy_config, null) == null ||
        try(v.service_lb_policy_config.load_balancing_algorithm, null) == null ||
        contains(
          ["SPRAY_TO_REGION", "WATERFALL_BY_REGION", "WATERFALL_BY_ZONE"],
          try(v.service_lb_policy_config.load_balancing_algorithm, "")
        )
      )
    ])
    error_message = "Invalid 'load_balancing_algorithm' value. Supported values are 'SPRAY_TO_REGION', 'WATERFALL_BY_REGION', 'WATERFALL_BY_ZONE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.backend_service_configs : (
        try(v.service_lb_policy_config, null) == null ||
        try(v.service_lb_policy_config.failover_health_threshold, null) == null ||
        (
          try(v.service_lb_policy_config.failover_health_threshold, 0) >= 1 &&
          try(v.service_lb_policy_config.failover_health_threshold, 0) <= 99
        )
      )
    ])
    error_message = "The 'failover_health_threshold' value must be between 1 and 99."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    addresses   = optional(map(string), {})
    locations   = optional(map(string), {})
    networks    = optional(map(string), {})
    project_ids = optional(map(string), {})
    subnets     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "Optional description used for resources."
  type        = string
  default     = "Terraform managed."
}

variable "group_configs" {
  description = "Optional unmanaged groups to create. Can be referenced in backends via key or outputs."
  type = map(object({
    name        = optional(string)
    description = optional(string, "Terraform managed.")
    zone        = string
    instances   = optional(list(string))
    named_ports = optional(map(number), {})
    project_id  = optional(string)
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
  description = "Optional auto-created health check configurations."
  type = object({
    name                = optional(string)
    check_interval_sec  = optional(number)
    description         = optional(string, "Terraform managed.")
    enable_logging      = optional(bool, false)
    healthy_threshold   = optional(number)
    project_id          = optional(string)
    timeout_sec         = optional(number)
    unhealthy_threshold = optional(number)
    grpc = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      service_name       = optional(string)
    }))
    http = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    http2 = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    https = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    tcp = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
    }))
    ssl = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
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
  validation {
    condition = alltrue([
      for k, v in var.health_check_config : contains([
        "-", "USE_FIXED_PORT", "USE_NAMED_PORT", "USE_SERVING_PORT"
      ], coalesce(try(v.port_specification, null), "-"))
    ])
    error_message = "Invalid 'port_specification' value. Supported values are 'USE_FIXED_PORT', 'USE_NAMED_PORT', 'USE_SERVING_PORT'."
  }
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
    gce = optional(object({
      zone       = string
      network    = optional(string)
      subnetwork = optional(string)
      endpoints = optional(map(object({
        instance   = string
        ip_address = string
        port       = number
      })), {})
    }))
    hybrid = optional(object({
      zone    = string
      network = optional(string)
      endpoints = optional(map(object({
        ip_address = string
        port       = number
      })), {})
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
        (try(v.gce, null) == null ? 0 : 1) +
        (try(v.hybrid, null) == null ? 0 : 1) +
        (try(v.psc, null) == null ? 0 : 1) == 1
      )
    ])
    error_message = "Only one type of neg can be configured at a time."
  }
}

variable "port" {
  description = "Forwarding rule port. Cross-region internal proxy load balancers support a single port."
  type        = number
  default     = 80
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "target_proxy_config" {
  description = "Target proxy configuration."
  type = object({
    description         = optional(string, "Terraform managed.")
    name                = optional(string)
    proxy_header        = optional(string)
    backend_service_key = optional(string)
  })
  default  = {}
  nullable = false
}

variable "tls_route_config" {
  description = "Optional TLS route configuration. When set, a google_network_services_tls_route is created targeting the load balancer's TCP proxy."
  type = object({
    name = string
    rules = list(object({
      matches = list(object({
        sni_host = optional(list(string))
        alpn     = optional(list(string))
      }))
      destinations = optional(list(object({
        service_name = string
        weight       = optional(number)
      })))
    }))
  })
  default = null
  validation {
    condition = var.tls_route_config == null || alltrue([
      for r in try(var.tls_route_config.rules, []) :
      length(r.matches) > 0
    ])
    error_message = "Each TLS route rule must have at least one match."
  }
}

variable "vpc_config" {
  description = "VPC-level configuration."
  type = object({
    network     = string
    subnetworks = map(string)
  })
  nullable = false
}
