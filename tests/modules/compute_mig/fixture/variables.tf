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

variable "autoscaler_config" {
  type = object({
    max_replicas                      = number
    min_replicas                      = number
    cooldown_period                   = number
    cpu_utilization_target            = number
    load_balancing_utilization_target = number
    metric = object({
      name                       = string
      single_instance_assignment = number
      target                     = number
      type                       = string # GAUGE, DELTA_PER_SECOND, DELTA_PER_MINUTE
      filter                     = string
    })
  })
  default = null
}

variable "auto_healing_policies" {
  type = object({
    health_check      = string
    initial_delay_sec = number
  })
  default = null
}

variable "health_check_config" {
  type = object({
    type    = string      # http https tcp ssl http2
    check   = map(any)    # actual health check block attributes
    config  = map(number) # interval, thresholds, timeout
    logging = bool
  })
  default = null
}

variable "named_ports" {
  type    = map(number)
  default = null
}

variable "regional" {
  type    = bool
  default = false
}

variable "update_policy" {
  type = object({
    type                 = string # OPPORTUNISTIC | PROACTIVE
    minimal_action       = string # REPLACE | RESTART
    min_ready_sec        = number
    max_surge_type       = string # fixed | percent
    max_surge            = number
    max_unavailable_type = string
    max_unavailable      = number
  })
  default = null
}

variable "versions" {
  type = map(object({
    instance_template = string
    target_type       = string # fixed | percent
    target_size       = number
  }))
  default = null
}
