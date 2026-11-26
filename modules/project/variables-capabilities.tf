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

variable "capability_configs" {
  description = "Resource Manager capability configurations keyed by capability config id. `boundaries` is only supported on organizations and folders (accepts keys from `boundary_configs.boundaries` or full resource names). `management_project` accepts `projects/{number}` or `$project_numbers:` context references; on projects it defaults to the project itself."
  type = map(object({
    boundaries         = optional(list(string), [])
    deletion_policy    = optional(string)
    display_name       = optional(string)
    management_project = optional(string)
    types              = optional(list(string), ["AGENT_MANAGEMENT"])
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.capability_configs : v != null
    ])
    error_message = "Capability config entries cannot be null; use {} instead."
  }
  validation {
    condition = alltrue([
      for k, v in var.capability_configs :
      can(regex("^[a-z0-9-]{6,30}$", k))
    ])
    error_message = "Capability config keys must be 6 to 30 lowercase letters, numbers, or hyphens."
  }
  validation {
    condition = alltrue([
      for k, v in var.capability_configs : (
        length(try(v.types, [])) > 0 &&
        alltrue([
          for t in try(v.types, []) :
          contains(["AGENT_MANAGEMENT"], t)
        ])
      )
    ])
    error_message = "Capability config types must be non-empty and contain only AGENT_MANAGEMENT."
  }
  validation {
    condition = alltrue([
      for k, v in var.capability_configs : (
        try(v.display_name, null) == null ||
        (length(v.display_name) >= 4 && length(v.display_name) <= 30)
      )
    ])
    error_message = "Capability config display_name must be between 4 and 30 characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.capability_configs : (
        try(v.management_project, null) == null ||
        startswith(v.management_project, "$project_numbers:") ||
        can(regex("^projects/[0-9]+$", v.management_project))
      )
    ])
    error_message = "management_project must be in `projects/{project_number}` format or a `$project_numbers:` context reference."
  }
  validation {
    condition = alltrue([
      for k, v in var.capability_configs : (
        try(v.deletion_policy, null) == null ||
        contains(["ABANDON", "DELETE", "PREVENT"], v.deletion_policy)
      )
    ])
    error_message = "Capability config deletion_policy must be one of ABANDON, DELETE, PREVENT."
  }
}
