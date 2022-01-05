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

variable "billing_account_id" {
  description = "Billing account id used to create projects."
  type        = string
}

variable "m4ce_project_root" {
  description = "Root node for the new m4ce host project, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "m4ce_project_name" {
  description = "Name of the project dedicated to M4CE as host and target for the migration"
  type        = string
  default     = "m4ce-host-project-000"
}

variable "m4ce_project_create" {
  description = "Enable the creation of a new project dedicated to M4CE"
  type        = bool
  default     = true
}

variable "m4ce_admin_users" {
  description = "List of users authorized to create new M4CE sources and perform all other migration operations, in IAM format."
  type        = list(string)
}

variable "m4ce_viewer_users" {
  description = "List of users authorized to retirve information about M4CE in the Google Cloud Console. Intended for users who are performing migrations, but not setting up the system or adding new migration sources, in IAM format."
  type        = list(string)
  default     = []
}

variable "m4ce_target_projects" {
  description = "List of target projects for m4ce workload migrations"
  type        = list(string)
}
