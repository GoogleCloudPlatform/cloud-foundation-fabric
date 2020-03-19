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

variable "audit_filter" {
  description = "Audit log filter used for the log sink."
  type        = string
  default     = <<END
  logName: "/logs/cloudaudit.googleapis.com%2Factivity"
  OR
  logName: "/logs/cloudaudit.googleapis.com%2Fsystem_event"
  END
}

variable "iam_audit_viewers" {
  description = "Audit project viewers, in IAM format."
  type        = list(string)
  default     = []
}

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "business_unit_bi" {
  description = "Business unit BI configuration."
  type = object({
    name                  = string
    short_name            = string
    iam_roles             = list(string)
    iam_members           = map(list(string))
    environment_iam_roles = list(string)
  })
  default = {
    name        = "Business Intelligence",
    short_name  = "bi"
    iam_roles   = [],
    iam_members = {},
    environment_iam_roles = [
      "roles/compute.networkAdmin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
    ]
  }
}

variable "business_unit_ml" {
  description = "Business unit ML configuration."
  type = object({
    name                  = string
    short_name            = string
    iam_roles             = list(string)
    iam_members           = map(list(string))
    environment_iam_roles = list(string)
  })
  default = {
    name        = "Machine Learning",
    short_name  = "ml"
    iam_roles   = [],
    iam_members = {},
    environment_iam_roles = [
      "roles/compute.networkAdmin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
    ]
  }
}


variable "environments" {
  description = "Environment short names."
  type        = map(string)
  default = {
    dev = "Development", 
    test = "Testing", 
    prod = "Production"
  }
}

variable "generate_service_account_keys" {
  description = "Generate and store service account keys in the state file."
  type        = bool
  default     = false
}

variable "gcs_defaults" {
  description = "Defaults use for the state GCS buckets."
  type        = map(string)
  default = {
    location      = "EU"
    storage_class = "MULTI_REGIONAL"
  }
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

variable "iam_shared_owners" {
  description = "Shared services project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "terraform_owners" {
  description = "Terraform project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  type        = list(string)
  default = [
    "resourceviews.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}

variable "iam_terraform_owners" {
  description = "Terraform project owners, in IAM format."
  type        = list(string)
  default     = []
}

variable "generate_keys" {
  description = "Generate keys for service accounts."
  type        = bool
  default     = false
}
