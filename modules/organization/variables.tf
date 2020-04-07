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

variable "org_id" {
  description = "Organization id in nnnnnn format."
  type        = number
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
