# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "business_unit_folder_name" {
  description = "Business Unit Folder name."
  type        = string
}

variable "environments" {
  description = "Environment short names."
  type        = list(string)
}

variable "per_folder_admins" {
  type        = list(string)
  description = "List of IAM-style members per folder who will get extended permissions."
  default     = []
}

variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}
