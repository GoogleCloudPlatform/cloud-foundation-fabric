/**
 * Copyright 2022 Google LLC
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

# Variables from 0-globals.auto.tfvars.json

variable "billing_account" {
  description = "Billing account configuration."
  type = object({
    id = string
  })
}

variable "groups" {
  description = "Organization groups."
  type        = map(string)
  default     = {}
}

variable "locations" {
  description = "Regional locations configuration."
  type = object({
    bigquery = string
    logging  = string
    pubsub   = list(string)
    storage  = string
  })
}

variable "organization" {
  description = "Organization configuration."
  type = object({
    customer_id = string
    domain      = string
    id          = string
  })
}

variable "prefix" {
  description = "Prefix for resource naming."
  type        = string
}

# Variables from 0-org-setup.auto.tfvars.json

variable "automation" {
  description = "Automation configuration from previous stages."
  type = object({
    outputs_bucket = string
  })
}

variable "custom_roles" {
  description = "Custom roles from previous stages."
  type        = map(string)
  default     = {}
}

variable "folder_ids" {
  description = "Folder IDs from previous stages."
  type        = map(string)
  default     = {}
}

variable "iam_principals" {
  description = "IAM principals from previous stages."
  type        = map(string)
  default     = {}
}

variable "logging" {
  description = "Logging configuration from previous stages."
  type = object({
    writer_identities = map(string)
  })
  default = {
    writer_identities = {}
  }
}

variable "project_ids" {
  description = "Project IDs from previous stages."
  type        = map(string)
  default     = {}
}

variable "project_numbers" {
  description = "Project numbers from previous stages."
  type        = map(string)
  default     = {}
}

variable "service_accounts" {
  description = "Service accounts from previous stages."
  type        = map(string)
  default     = {}
}

variable "storage_buckets" {
  description = "Storage buckets from previous stages."
  type        = map(string)
  default     = {}
}

variable "tag_values" {
  description = "Tag values from previous stages."
  type        = map(string)
  default     = {}
}