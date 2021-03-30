# Copyright 2021 Google LLC
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

variable "audit_filter" {
  description = "Audit log filter used for the log sink."
  type        = string
  default     = <<END
  logName: "/logs/cloudaudit.googleapis.com%2Factivity"
  OR
  logName: "/logs/cloudaudit.googleapis.com%2Fsystem_event"
  END
}

variable "billing_account_id" {
  description = "Billing account id used as to create projects."
  type        = string
}

variable "environments" {
  description = "Environment short names."
  type        = set(string)
}

variable "gcs_location" {
  description = "GCS bucket location."
  type        = string
  default     = "EU"
}

variable "iam_audit_viewers" {
  description = "Audit project viewers, in IAM format."
  type        = list(string)
  default     = []
}

variable "iam_billing_config" {
  description = "Control granting billing user role to service accounts. Target the billing account by default."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}

variable "iam_folder_roles" {
  description = "List of roles granted to each service account on its respective folder (excluding XPN roles)."
  type        = list(string)
  default = [
    "roles/compute.networkAdmin",
    "roles/owner",
    "roles/resourcemanager.folderViewer",
    "roles/resourcemanager.projectCreator",
  ]
}

variable "iam_shared_owners" {
  description = "Shared services project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "iam_terraform_owners" {
  description = "Terraform project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "iam_xpn_config" {
  description = "Control granting Shared VPC creation roles to service accounts. Target the root node by default."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = true
  }
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnnnn format."
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

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  type        = list(string)
  default = [
    "container.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}

variable "service_account_keys" {
  description = "Generate and store service account keys in the state file."
  type        = bool
  default     = true
}
