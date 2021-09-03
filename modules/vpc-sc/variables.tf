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

variable "access_levels" {
  description = "Map of Access Levels to be created. For each Access Level you can specify 'ip_subnetworks, required_access_levels, members, negate or regions'."
  type = map(object({
    combining_function = string
    conditions = list(object({
      ip_subnetworks         = list(string)
      required_access_levels = list(string)
      members                = list(string)
      negate                 = string
      regions                = list(string)
    }))
  }))
  default = {}
}

variable "access_policy_create" {
  description = "Enable autocreation of the Access Policy"
  type        = bool
  default     = true
}

variable "access_policy_name" {
  description = "Referenced Access Policy name"
  type        = string
  default     = null
}

variable "access_level_perimeters" {
  description = "Enforced mode -> Access Level -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run'"
  type        = map(map(list(string)))
  default     = {}
}

variable "access_policy_title" {
  description = "Access Policy title to be created."
  type        = string
  default     = null
}

variable "egress_policies" {
  description = "List of EgressPolicies in the form described in the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#egress_policies)"
  default     = null
}

variable "egress_policies_perimeters" {
  description = "Enforced mode -> Egress Policy -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run'"
  type        = map(map(list(string)))
  default     = {}
}

variable "ingress_policies" {
  description = "List of IngressPolicies in the form described in the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#ingress_policies)"
  default     = null
}

variable "ingress_policies_perimeters" {
  description = "Enforced mode -> Ingress Policy -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run'"
  type        = map(map(list(string)))
  default     = {}
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
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
