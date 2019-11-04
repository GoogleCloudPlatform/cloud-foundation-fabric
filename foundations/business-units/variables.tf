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

variable "audit_viewers" {
  description = "Audit project viewers, in IAM format."
  default     = []
}

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "business_unit_1_name" {
  description = "Business unit 1 short name."
  type        = string
}

variable "business_unit_2_name" {
  description = "Business unit 2 short name."
  type        = string
}

variable "business_unit_3_name" {
  description = "Business unit 3 short name."
  type        = string
}

variable "environments" {
  description = "Environment short names."
  type        = list(string)
}

variable "generate_service_account_keys" {
  description = "Generate and store service account keys in the state file."
  default     = false
}

variable "gcs_location" {
  description = "GCS bucket location."
  default     = "EU"
}

variable "organization_id" {
  description = "Organization id."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "shared_bindings_members" {
  description = "List of comma-delimited IAM-format members for the additional shared project bindings."
  # example: ["user:a@example.com,b@example.com", "user:c@example.com"]
  default = []
}
variable "shared_bindings_roles" {
  description = "List of roles for additional shared project bindings."
  # example: ["roles/storage.objectViewer", "roles/storage.admin"]
  default = []
}

variable "terraform_owners" {
  description = "Terraform project owners, in IAM format."
  default     = []
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "resourceviews.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}
