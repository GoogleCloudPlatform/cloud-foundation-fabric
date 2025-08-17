/**
 * Copyright 2024 Google LLC
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

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
  nullable = false
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id."
  type = object({
    id = string
  })
}

variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "folder_ids" {
  # tfdoc:variable:source 0-bootstrap
  description = "Folders created in the bootstrap stage."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "iam_principals" {
  # tfdoc:variable:source 0-bootstrap
  description = "IAM-format principals."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Host project for the shared VPC."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "kms_keys" {
  # tfdoc:variable:source 2-security
  description = "KMS key ids."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    storage = optional(string, "eu")
  })
  nullable = false
  default  = {}
}

variable "perimeters" {
  # tfdoc:variable:source 1-vpcsc
  description = "Optional VPC-SC perimeter ids."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 12
    error_message = "Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  }
}

variable "project_ids" {
  # tfdoc:variable:source 0-bootstrap
  description = "Projects created in the bootstrap stage."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "service_accounts" {
  # tfdoc:variable:source 0-bootstrap
  description = "Service accounts created in the bootstrap stage."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "tag_values" {
  # tfdoc:variable:source 0-bootstrap
  description = "FAST-managed resource manager tag values."
  type        = map(string)
  nullable    = false
  default     = {}
}
