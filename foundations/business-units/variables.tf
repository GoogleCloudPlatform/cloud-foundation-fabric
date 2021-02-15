/**
 * Copyright 2021 Google LLC
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
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "environments" {
  description = "Environment short names."
  type        = map(string)
  default = {
    dev  = "Development",
    test = "Testing",
    prod = "Production"
  }
}

variable "gcs_defaults" {
  description = "Defaults use for the state GCS buckets."
  type        = map(string)
  default = {
    location      = "EU"
    storage_class = "MULTI_REGIONAL"
  }
}

variable "iam_audit_viewers" {
  description = "Audit project viewers, in IAM format."
  type        = list(string)
  default     = []
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

variable "organization_id" {
  description = "Organization id in organizations/nnnnnnn format."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
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
variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}
