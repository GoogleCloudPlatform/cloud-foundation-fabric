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

variable "auto_healing_policies" {
  description = "Auto-healing policies for this group."
  type = object({
    health_check      = string
    initial_delay_sec = number
  })
  default = null
}

variable "autoscaler_config" {
  description = "Optional autoscaler configuration. Only one of 'cpu_utilization_target' 'load_balancing_utilization_target' or 'metric' can be not null."
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

variable "default_version" {
  description = "Default application version template. Additional versions can be specified via the `versions` variable."
  type = object({
    instance_template = string
    name              = string
  })
}

variable "health_check_config" {
  description = "Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage."
  type = object({
    type    = string      # http https tcp ssl http2
    check   = map(any)    # actual health check block attributes
    config  = map(number) # interval, thresholds, timeout
    logging = bool
  })
  default = null
}

variable "location" {
  description = "Compute zone, or region if `regional` is set to true."
  type        = string
}
variable "name" {
  description = "Managed group name."
  type        = string
}

variable "named_ports" {
  description = "Named ports."
  type        = map(number)
  default     = null
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "regional" {
  description = "Use regional instance group. When set, `location` should be set to the region."
  type        = bool
  default     = false
}

variable "stateful_config" {
  description = "Stateful configuration can be done by individual instances or for all instances in the MIG. They key in per_instance_config is the name of the specific instance. The key of the stateful_disks is the 'device_name' field of the resource. Please note that device_name is defined at the OS mount level, unlike the disk name."
  type = object({
    per_instance_config = map(object({
      #name is the key
      #name = string
      stateful_disks = map(object({
        #device_name is the key
        source      = string
        mode        = string # READ_WRITE | READ_ONLY 
        delete_rule = string # NEVER | ON_PERMANENT_INSTANCE_DELETION
      }))
      metadata = map(string)
      update_config = object({
        minimal_action                   = string # NONE | REPLACE | RESTART | REFRESH
        most_disruptive_allowed_action   = string # REPLACE | RESTART | REFRESH | NONE
        remove_instance_state_on_destroy = bool
      })
    }))

    mig_config = object({
      stateful_disks = map(object({
        #device_name is the key
        delete_rule = string # NEVER | ON_PERMANENT_INSTANCE_DELETION
      }))
    })

  })
  default = null
}

variable "target_pools" {
  description = "Optional list of URLs for target pools to which new instances in the group are added."
  type        = list(string)
  default     = []
}

variable "target_size" {
  description = "Group target size, leave null when using an autoscaler."
  type        = number
  default     = null
}

variable "update_policy" {
  description = "Update policy. Type can be 'OPPORTUNISTIC' or 'PROACTIVE', action 'REPLACE' or 'restart', surge type 'fixed' or 'percent'."
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
  description = "Additional application versions, target_type is either 'fixed' or 'percent'."
  type = map(object({
    instance_template = string
    target_type       = string # fixed | percent
    target_size       = number
  }))
  default = null
}

variable "wait_for_instances" {
  description = "Wait for all instances to be created/updated before returning."
  type        = bool
  default     = null
}
