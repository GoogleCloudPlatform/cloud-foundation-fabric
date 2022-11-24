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

# tfdoc:file:description Health check variable.

variable "health_check_configs" {
  description = "Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage."
  type = map(object({
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
  }))
  default = {
    default = {
      http = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
  validation {
    condition = alltrue([
      for k, v in var.health_check_configs : (
        (try(v.grpc, null) == null ? 0 : 1) +
        (try(v.http, null) == null ? 0 : 1) +
        (try(v.tcp, null) == null ? 0 : 1) <= 1
      )
    ])
    error_message = "Only one health check type can be configured at a time."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.health_check_configs : [
        for kk, vv in v : contains([
          "-", "USE_FIXED_PORT", "USE_NAMED_PORT", "USE_SERVING_PORT"
        ], coalesce(try(vv.port_specification, null), "-"))
      ]
    ]))
    error_message = "Invalid 'port_specification' value. Supported values are 'USE_FIXED_PORT', 'USE_NAMED_PORT', 'USE_SERVING_PORT'."
  }
}
