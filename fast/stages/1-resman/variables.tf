/**
 * Copyright 2024 Google LLC
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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    stage_2           = optional(string, "data/stage-2")
    stage_3           = optional(string, "data/stage-3")
    tags              = optional(string, "data/tags")
    top_level_folders = optional(string, "data/top-level-folders")
    context = optional(object({
      org_policies = optional(map(map(string)), {})
      tag_keys     = optional(map(string), {})
      tag_values   = optional(map(string), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
  type        = string
  default     = null
}

variable "resource_names" {
  description = "Resource names overrides for specific resources. Stage names are interpolated via `$${name}`. Prefix is always set via code, except where noted in the variable type."
  type = object({
    gcs-net      = optional(string, "prod-resman-$${name}-0")
    gcs-nsec     = optional(string, "resman-$${name}-0")
    gcs-pf       = optional(string, "resman-$${name}-0")
    gcs-sec      = optional(string, "prod-resman-$${name}-0")
    gcs-stage2   = optional(string, "resman-$${name}-0")
    gcs-stage3   = optional(string, "resman-$${name}-0")
    sa-cicd_ro   = optional(string, "resman-$${name}-1r")
    sa-cicd_rw   = optional(string, "resman-$${name}-1")
    sa-stage2_ro = optional(string, "resman-$${name}-0r")
    sa-stage2_rw = optional(string, "resman-$${name}-0")
    sa-stage3_ro = optional(string, "resman-$${name}-0r")
    sa-stage3_rw = optional(string, "resman-$${name}-0")
  })
  nullable = false
  default  = {}
}

variable "tag_names" {
  description = "Customized names for resource management tags."
  type = object({
    context     = optional(string, "context")
    environment = optional(string, "environment")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tags" {
  description = "Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level."
  type = map(object({
    description = optional(string, "Managed by the Terraform organization module.")
    iam         = optional(map(list(string)), {})
    id          = optional(string)
    values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}
