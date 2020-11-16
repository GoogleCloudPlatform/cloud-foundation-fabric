/**
 * Copyright 2020 Google LLC
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

variable "access_levels" {
  description = "Access Levels."
  type = map(object({
    combining_function = string
    conditions = list(object({
      ip_subnetworks = list(string)
      members        = list(string)
      negate         = string
    }))
  }))
  default = {}
}

variable "access_level_perimeters" {
  description = "Enforced mode -> Access Level -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run'"
  type        = map(map(list(string)))
  default     = {}
}

variable "access_policy_title" {
  description = "Access Policy title to be created."
  type        = string
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = number
}

variable "perimeters" {
  description = "Set of Perimeters."
  type = map(object({
    type = string
    dry_run_config = object({
      restricted_services     = list(string)
      vpc_accessible_services = list(string)
    })
    enforced_config = object({
      restricted_services     = list(string)
      vpc_accessible_services = list(string)
    })
  }))
  default = {}
}

variable "perimeter_projects" {
  description = "Perimeter -> Enforced Mode -> Projects Number mapping. Enforced mode can be 'enforced' or 'dry_run'."
  type        = map(map(list(number)))
  default     = {}
}
