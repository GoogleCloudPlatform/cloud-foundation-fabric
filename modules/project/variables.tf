/**
 * Copyright 2019 Google LLC
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
  default     = ""
}

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
}

variable "iam_members" {
  description = "Map of member lists used to set authoritative bindings, keyed by role."
  type        = map(list(string))
  default     = {}
}

variable "iam_roles" {
  description = "List of roles used to set authoritative bindings."
  type        = list(string)
  default     = []
}

variable "iam_additive_members" {
  description = "Map of member lists used to set non authoritative bindings, keyed by role."
  type        = map(list(string))
  default     = {}
}

variable "iam_additive_roles" {
  description = "List of roles used to set non authoritative bindings."
  type        = list(string)
  default     = []
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
  description = "The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id."
  type        = string
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

variable "services" {
  description = "Service APIs to enable."
  type        = list(string)
  default     = []
}
