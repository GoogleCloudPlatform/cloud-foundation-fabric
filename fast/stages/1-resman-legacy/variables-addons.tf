/**
 * Copyright 2025 Google LLC
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

variable "fast_addon" {
  description = "FAST addons configurations for stages 2. Keys are used as short names for the add-on resources."
  type = map(object({
    parent_stage = string
    cicd_config = optional(object({
      identity_provider = string
      repository = object({
        name   = string
        branch = optional(string)
        type   = optional(string, "github")
      })
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.fast_addon :
      startswith(v.parent_stage, "2-")
    ])
    error_message = "The parent stage of resman-defined addons should match '2-<stage2-name>'."
  }
  validation {
    condition = alltrue([
      for k, v in var.fast_addon :
      v.cicd_config == null || contains(
        ["github", "gitlab"],
        coalesce(try(v.cicd_config.repository.type, null), "-")
      )
    ])
    error_message = "Invalid CI/CD repository type."
  }
}

check "addons_parent_stage" {
  assert {
    condition = alltrue([
      for k, v in var.fast_addon : contains(
        [for x in keys(local.stage2) : "2-${x}"],
        v.parent_stage
      )
    ])
    error_message = "Resman-defined addons only support stage 2 as parents."
  }
}
