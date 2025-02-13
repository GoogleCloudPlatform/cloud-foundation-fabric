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
    affinity_cookie_ttl_sec         = optional(number)
    connection_draining_timeout_sec = optional(number)
    health_checks                   = optional(list(string), ["default"])
    log_sample_rate                 = optional(number)
    port_name                       = optional(string)
    project_id                      = optional(string)
    session_affinity                = optional(string, "NONE")
    timeout_sec                     = optional(number)
    backends = optional(list(object({
      group           = string
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1)
      description     = optional(string, "Terraform managed.")
      failover        = optional(bool, false)
      max_connections = optional(object({
        per_endpoint = optional(number)
        per_group    = optional(number)
        per_instance = optional(number)
      }))
      max_utilization = optional(number)
    })))
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
  })
  default  = {}
  nullable = false
  validation {
    condition = (var.backend_service_config == null || contains(["NONE", "CLIENT_IP"],
      var.backend_service_config.session_affinity
    ))
    error_message = "Invalid session affinity value."
  }
  validation {
    condition = alltrue([
      for b in var.backend_service_config.backends : contains(
        ["CONNECTION", "UTILIZATION"], coalesce(b.balancing_mode, "CONNECTION")
    )])
    error_message = "When specified, balancing mode needs to be 'CONNECTION' or 'UTILIZATION'."
  }
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
  description = "Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage."
  type = object({
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
      zone = string
      # default_port = optional(number)
      network    = optional(string)
      subnetwork = optional(string)
      endpoints = optional(map(object({
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
      endpoints = optional(map(object({
        ip_address = string
        port       = number
      })))
    }))
    internet = optional(object({
      region   = string
      use_fqdn = optional(bool, true)
      # re-enable once provider properly support this
      # default_port = optional(number)
      endpoints = optional(map(object({
        destination = string
        port        = number
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
        (try(v.gce, null) == null ? 0 : 1) +
        (try(v.hybrid, null) == null ? 0 : 1) +
        (try(v.internet, null) == null ? 0 : 1) +
        (try(v.psc, null) == null ? 0 : 1) == 1
      )
    ])
    error_message = "Only one type of neg can be configured at a time."
  }
}

variable "port" {
  description = "Port."
  type        = number
  default     = 80
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "region" {
  description = "The region where to allocate the ILB resources."
  type        = string
}

variable "service_attachment" {
  description = "PSC service attachment."
  type = object({
    nat_subnets           = list(string)
    automatic_connection  = optional(bool, false)
    consumer_accept_lists = optional(map(string), {}) # map of `project_id` => `connection_limit`
    consumer_reject_lists = optional(list(string))
    description           = optional(string)
    domain_name           = optional(string)
    enable_proxy_protocol = optional(bool, false)
    reconcile_connections = optional(bool)
  })
  default = null
}

variable "vpc_config" {
  description = "VPC-level configuration."
  type = object({
    network    = string
    subnetwork = string
  })
  nullable = false
}
