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

variable "custom_roles" {
  description = "Map of role name => list of permissions to create in this project."
  type        = map(list(string))
  default     = {}
}

variable "iam" {
  description = "IAM bindings, in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_additive" {
  description = "Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_additive_members" {
  description = "IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values."
  type        = map(list(string))
  default     = {}
}

variable "iam_audit_config" {
  description = "Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service."
  type        = map(map(list(string)))
  default     = {}
  # default = {
  #   allServices = {
  #     DATA_READ = ["user:me@example.org"]
  #   }
  # }
}

variable "iam_bindings_authoritative" {
  description = "IAM authoritative bindings, in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared. Bindings should also be authoritative when using authoritative audit config. Use with caution."
  type        = map(list(string))
  default     = null
}

variable "iam_audit_config_authoritative" {
  description = "IAM Authoritative service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. Audit config should also be authoritative when using authoritative bindings. Use with caution."
  type        = map(map(list(string)))
  default     = null
  # default = {
  #   allServices = {
  #     DATA_READ = ["user:me@example.org"]
  #   }
  # }
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
  validation {
    condition     = can(regex("^organizations/[0-9]+", var.organization_id))
    error_message = "The organization_id must in the form organizations/nnn."
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

variable "firewall_policies" {
  description = "Hierarchical firewall policies to *create* in the organization."
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
    #preview                 = bool
  })))
  default = {}
}

variable "firewall_policy_attachments" {
  description = "List of hierarchical firewall policy IDs to *attach* to the organization"
  # set to avoid manual casting with toset()
  type    = map(string)
  default = {}
}

variable "logging_sinks" {
  description = "Logging sinks to create for this organization."
  type = map(object({
    destination      = string
    type             = string
    filter           = string
    iam              = bool
    include_children = bool
  }))
  default = {}
}

variable "logging_exclusions" {
  description = "Logging exclusions for this organization in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
}
