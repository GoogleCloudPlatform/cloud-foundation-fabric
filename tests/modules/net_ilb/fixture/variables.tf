/**
 * Copyright 2021 Google LLC
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
  type    = string
  default = null
}

variable "backends" {
  type = list(object({
    failover       = bool
    group          = string
    balancing_mode = string
  }))
}

variable "backend_config" {
  type = object({
    session_affinity                = string
    timeout_sec                     = number
    connection_draining_timeout_sec = number
  })
  default = null
}

variable "failover_config" {
  type = object({
    disable_connection_drain  = bool
    drop_traffic_if_unhealthy = bool
    ratio                     = number
  })
  default = null
}

variable "global_access" {
  type    = bool
  default = null
}

variable "health_check" {
  type    = string
  default = null
}

variable "health_check_config" {
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

variable "ports" {
  type    = list(string)
  default = null
}

variable "protocol" {
  type    = string
  default = "TCP"
}

variable "service_label" {
  type    = string
  default = null
}
