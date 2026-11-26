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

variable "boundary_configs" {
  description = "Resource Manager management boundary configuration and boundaries. When `tag_key` is set (namespaced `{parent_id}/{short_name}` format, supporting `templatestring` via `context.tag_vars`), a singleton `BoundaryConfig` is configured and each boundary must specify `tag_value`. When `tag_key` is omitted, at most one unfiltered boundary can be created."
  type = object({
    boundaries = optional(map(object({
      deletion_policy = optional(string)
      display_name    = optional(string)
      tag_value       = optional(string)
    })), {})
    deletion_policy = optional(string)
    tag_key         = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      var.boundary_configs.tag_key == null || (
        !startswith(var.boundary_configs.tag_key, "tagKeys/") && (
          can(regex("^[^/]+/[^/]+$", var.boundary_configs.tag_key)) ||
          strcontains(var.boundary_configs.tag_key, "$${")
        )
      )
    )
    error_message = "tag_key must use the namespaced `{parent_id}/{short_name}` format (or a `tag_vars` template), not `tagKeys/{id}`."
  }
  validation {
    condition = (
      var.boundary_configs.deletion_policy == null ||
      contains(
        ["ABANDON", "DELETE", "PREVENT"],
        var.boundary_configs.deletion_policy
      )
    )
    error_message = "deletion_policy must be one of ABANDON, DELETE, PREVENT."
  }
  validation {
    condition = (
      var.boundary_configs.tag_key != null ||
      var.boundary_configs.deletion_policy == null
    )
    error_message = "boundary_configs.deletion_policy can only be set when tag_key is set."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.boundary_configs.boundaries, {}) : v != null
    ])
    error_message = "Boundary entries cannot be null; use {} instead."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.boundary_configs.boundaries, {}) :
      can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", k))
    ])
    error_message = "Boundary keys must be 6 to 30 lowercase letters, digits, or hyphens, starting with a letter and not ending with a hyphen."
  }
  validation {
    condition = (
      var.boundary_configs.tag_key != null ||
      length(coalesce(var.boundary_configs.boundaries, {})) <= 1
    )
    error_message = "At most one boundary can be created when tag_key is not set."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.boundary_configs.boundaries, {}) : (
        var.boundary_configs.tag_key == null
        ? try(v.tag_value, null) == null
        : try(v.tag_value, null) != null && try(v.tag_value, "") != ""
      )
    ])
    error_message = "Boundary tag_value is required when boundary_configs.tag_key is set, and must be null when tag_key is unset."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.boundary_configs.boundaries, {}) : (
        try(v.display_name, null) == null ||
        can(regex("^[a-zA-Z0-9-'\" !]{4,30}$", v.display_name))
      )
    ])
    error_message = "Boundary display_name must be 4 to 30 valid characters."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.boundary_configs.boundaries, {}) : (
        try(v.deletion_policy, null) == null ||
        contains(["ABANDON", "DELETE", "PREVENT"], v.deletion_policy)
      )
    ])
    error_message = "Boundary deletion_policy must be one of ABANDON, DELETE, PREVENT."
  }
}
