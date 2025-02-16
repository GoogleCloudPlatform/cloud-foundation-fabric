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

variable "access_policy" {
  description = "Access policy id (used for tenant-level VPC-SC configurations)."
  type        = number
  default     = null
}

variable "factories_config" {
  description = "Paths to folders that enable factory functionality."
  type = object({
    access_levels       = optional(string, "data/access-levels")
    egress_policies     = optional(string, "data/egress-policies")
    ingress_policies    = optional(string, "data/ingress-policies")
    perimeters          = optional(string, "data/perimeters")
    restricted_services = optional(string, "data/restricted-services.yaml")
  })
  nullable = false
  default  = {}
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "resource_discovery" {
  description = "Automatic discovery of perimeter projects."
  type = object({
    enabled          = optional(bool, true)
    ignore_folders   = optional(list(string), [])
    ignore_projects  = optional(list(string), [])
    include_projects = optional(list(string), [])
  })
  nullable = false
  default  = {}
}
