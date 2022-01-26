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

variable "project_create" {
  description = "Define when to create a new project or use an existing one."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_name" {
  description = "Name of the project dedicated to M4CE as host and target for the migration. It could be an existing one or a new one."
  type        = string
  default     = "m4ce-host-project-000"
}

variable "migration_admin_users" {
  description = "List of users authorized to create new M4CE sources and perform all other migration operations, in IAM format."
  type        = list(string)
}

variable "migration_viewer_users" {
  description = "List of users authorized to retirve information about M4CE in the Google Cloud Console. Intended for users who are performing migrations, but not setting up the system or adding new migration sources, in IAM format."
  type        = list(string)
  default     = []
}

variable "migration_target_projects" {
  description = "List of target projects for m4ce workload migrations"
  type        = list(string)
}
