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

variable "billing_account" {
  type    = string
  default = "1234-ABCD-1234"
}

variable "project_create" {
  type    = bool
  default = true
}

variable "project_id" {
  type    = string
  default = "project-1"
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "tfe_organization_id" {
  description = "TFE organization id."
  type        = string
  default     = "org-123"
}

variable "tfe_workspace_id" {
  description = "TFE workspace id."
  type        = string
  default     = "ws-123"
}

variable "workload_identity_pool_id" {
  description = "Workload identity pool id."
  type        = string
  default     = "tfe-pool"
}

variable "workload_identity_pool_provider_id" {
  description = "Workload identity pool provider id."
  type        = string
  default     = "tfe-provider"
}

variable "issuer_uri" {
  description = "Terraform Enterprise uri. Replace the uri if a self hosted instance is used."
  type        = string
  default     = "https://app.terraform.io/"
}