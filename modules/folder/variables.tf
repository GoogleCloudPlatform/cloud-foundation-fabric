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

variable "contacts" {
  description = "List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES"
  type        = map(list(string))
  default     = {}
}

variable "firewall_policies" {
  description = "Hierarchical firewall policies to *create* in this folder."
  type = map(map(object({
    description             = string
    direction               = string
    action                  = string
    priority                = number
    ranges                  = list(string)
    ports                   = map(list(string))
    target_service_accounts = list(string)
    target_resources        = list(string)
    logging                 = bool
  })))
  default = {}
}

variable "firewall_policy_attachments" {
  description = "List of hierarchical firewall policy IDs to *attach* to this folder."
  type        = map(string)
  default     = {}
}

variable "folder_create" {
  description = "Create folder. When set to false, uses id to reference an existing folder."
  type        = bool
  default     = true
}

variable "group_iam" {
  description = "Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable."
  type        = map(list(string))
  default     = {}
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "id" {
  description = "Folder ID in case you use folder_create=false"
  type        = string
  default     = null
}

variable "logging_sinks" {
  description = "Logging sinks to create for this folder."
  type = map(object({
    destination      = string
    type             = string
    filter           = string
    iam              = bool
    include_children = bool
    # TODO exclusions also support description and disabled
    exclusions = map(string)
  }))
  default = {}
}

variable "logging_exclusions" {
  description = "Logging exclusions for this folder in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Folder name."
  type        = string
  default     = null
}

variable "parent" {
  description = "Parent in folders/folder_id or organizations/org_id format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
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
