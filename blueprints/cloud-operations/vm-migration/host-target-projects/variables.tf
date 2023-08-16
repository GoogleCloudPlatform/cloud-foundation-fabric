# Copyright 2022 Google LLC
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

variable "migration_admin" {
  description = "User or group who can create a new M4CE sources and perform all other migration operations, in IAM format (`group:foo@example.com`)."
  type        = string
}

variable "migration_target_projects" {
  description = "List of target projects for m4ce workload migrations."
  type        = list(string)
}

variable "migration_viewer" {
  description = "User or group authorized to retrieve information about M4CE in the Google Cloud Console, in IAM format (`group:foo@example.com`)."
  type        = string
  default     = null
}

variable "project_create" {
  description = "Parameters for the creation of the new project to host the M4CE backend."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_name" {
  description = "Name of an existing project or of the new project assigned as M4CE host project."
  type        = string
  default     = "m4ce-host-project-000"
}
