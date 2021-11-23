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

variable "minimal_action" {
  description = "Minimal action to perform on instance during update. Can be 'NONE', 'REPLACE', 'RESTART' and 'REFRESH'."
  type        = string # NONE | REPLACE | RESTART | REFRESH
  default     = "NONE"
}

variable "most_disruptive_allowed_action" {
  description = "Most disruptive action to perform on instance during update. Can be 'REPLACE, 'RESTART', 'REFRESH' or 'NONE'."
  type        = string # REPLACE | RESTART | REFRESH | NONE
  default     = "REPLACE"
}

variable "named_ports" {
  type    = map(number)
  default = null
}

variable "regional" {
  type    = bool
  default = false
}

variable "stateful_disk_mig" {
  description = "Stateful disk(s) config defined at the MIG level. Delete rule can be 'NEVER' or 'ON_PERMANENT_INSTANCE_DELETION'."
  type = map(object({
    delete_rule = string # NEVER | ON_PERMANENT_INSTANCE_DELETION
  }))
  default = null
}

variable "stateful_disk_instance" {
  description = "Stateful disk(s) config defined at the instance config level. Mode can be 'READ_WRITE' or 'READ_ONLY', delete rule can be 'NEVER' or 'ON_PERMANENT_INSTANCE_DELETION'."
  type = map(object({
    source      = string
    mode        = string # READ_WRITE | READ_ONLY 
    delete_rule = string # NEVER | ON_PERMANENT_INSTANCE_DELETION
  }))
  default = null
}

variable "stateful_metadata_instance" {
  description = "Stateful metadata defined at the instance config level. A value associated with a key 'instance_template' will tie this resource to the instance template lifecycle. "
  type        = map(string)
  default     = {}
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
