/**
 * Copyright 2018 Google LLC
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

variable "iam_members" {
  description = "List of IAM members keyed by folder name and role."
  type        = map(map(list(string)))
  default     = null
}

variable "iam_roles" {
  description = "List of IAM roles keyed by folder name."
  type        = map(list(string))
  default     = null
}

variable "names" {
  description = "Folder names."
  type        = list(string)
  default     = []
}

variable "parent" {
  description = "Parent in folders/folder_id or organizations/org_id format."
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
