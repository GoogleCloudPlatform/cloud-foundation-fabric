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

variable "auto_create_network" {
  description = "Whether to create the default network for the project"
  type        = bool
  default     = false
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
}

variable "iam_members" {
  description = "Map of member lists used to set authoritative bindings, keyed by role."
  type        = map(set(string))
  default     = {}
}

variable "iam_additive_bindings" {
  description = "Map of roles lists used to set non authoritative bindings, keyed by members"
  type        = map(list(string))
  default     = {}
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "lien_reason" {
  description = "If non-empty, creates a project lien with this description."
  type        = string
  default     = ""
}

variable "name" {
  description = "Project name and id suffix."
  type        = string
}

variable "oslogin" {
  description = "Enable OS Login."
  type        = bool
  default     = false
}

variable "oslogin_admins" {
  description = "List of IAM-style identities that will be granted roles necessary for OS Login administrators."
  type        = list(string)
  default     = []
}

variable "oslogin_users" {
  description = "List of IAM-style identities that will be granted roles necessary for OS Login users."
  type        = list(string)
  default     = []
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "policy_boolean" {
  description = "Map of boolean org policies and enforcement value, set value to null for policy restore."
  type        = map(bool)
  default     = {}
}

variable "policy_list" {
  description = "Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny."
  type = map(object({
    inherit_from_parent = bool
    suggested_value     = string
    status              = bool
    values              = list(string)
  }))
  default = {}
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = true
}

variable "services" {
  description = "Service APIs to enable."
  type        = list(string)
  default     = []
}

variable "service_config" {
  description = "Configure service API activation."
  type = object({
    disable_on_destroy         = bool
    disable_dependent_services = bool
  })
  default = {
    disable_on_destroy         = true
    disable_dependent_services = true
  }
}

variable "shared_vpc_host_config" {
  description = "Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project)."
  type = object({
    enabled          = bool
    service_projects = list(string)
  })
  default = {
    enabled          = false
    service_projects = []
  }
}

variable "shared_vpc_service_config" {
  description = "Configures this project as a Shared VPC service project (mutually exclusive with shared_vpc_host_config)."
  type = object({
    attach       = bool
    host_project = string
  })
  default = {
    attach       = false
    host_project = ""
  }
}
