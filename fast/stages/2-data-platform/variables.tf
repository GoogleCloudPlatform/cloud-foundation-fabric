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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars        = optional(map(map(string)), {})
    custom_roles          = optional(map(string), {})
    email_addresses       = optional(map(string), {})
    folder_ids            = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    locations             = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids           = optional(map(string), {})
    tag_values            = optional(map(string), {})
    vpc_host_projects     = optional(map(string), {})
    vpc_sc_perimeters     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    dataset = optional(string, "datasets/classic")
    paths = optional(object({
      defaults          = optional(string, "defaults.yaml")
      folders           = optional(string, "folders")
      projects          = optional(string, "projects")
      project_templates = optional(string, "project-templates")
      budgets           = optional(string)
    }), {})
  })
  nullable = false
  default  = {}
}

# variable "outputs_location" {
#   description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
#   type        = string
#   default     = null
# }

variable "stage_name" {
  description = "FAST stage name. Used to separate output files across different factories."
  type        = string
  nullable    = false
  default     = "2-data-platform"
}
