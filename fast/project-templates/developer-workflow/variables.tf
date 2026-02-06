/**
 * Copyright 2025 Google LLC
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
  description = "Automation options."
  type        = any
  default     = {}
}

variable "billing_account" {
  description = "Billing account id."
  type = object({
    id = string
  })
}

variable "data_file" {
  description = "Path to the YAML data file."
  type        = string
  default     = "data/values.yaml"
}

variable "iam_principals" {
  description = "Org-level IAM principals."
  type        = map(string)
  default     = {}
}

variable "locations" {
  description = "GCP locations."
  type = object({
    bigquery = string
    logging  = string
    pubsub   = list(string)
    storage  = string
  })
  default = {
    bigquery = "", logging = "", pubsub = [], storage = ""
  }
}

variable "logging" {
  description = "Log writer identities for organization / folders."
  type = object({
    writer_identities = map(string)
    project_number    = optional(string)
  })
  default = null
}

variable "organization" {
  description = "Organization details."
  type = object({
    domain      = string
    id          = string
    customer_id = string
  })
  default = {
    domain = ""
    # dummy values for plan to succeed
    id          = "0"
    customer_id = ""
  }
}

variable "prefix" {
  description = "Prefix used for project ids."
  type        = string
}

variable "project_numbers" {
  description = "Project numbers."
  type        = map(number)
  default     = {}
}

variable "root_node" {
  description = "Root node for the hierarchy, if running in tenant mode."
  type        = string
  default     = null
}

variable "service_accounts" {
  description = "Org-level service accounts."
  type        = map(string)
  default     = {}
}

variable "storage_buckets" {
  description = "Storage buckets created in the bootstrap stage."
  type        = map(string)
  default     = {}
}

variable "tag_values" {
  description = "Tag values."
  type        = map(string)
  default     = {}
}

variable "universe" {
  description = "GCP universe where to deploy the project. The prefix will be prepended to the project id."
  type = object({
    prefix                         = string
    forced_jit_service_identities  = optional(list(string), [])
    unavailable_services           = optional(list(string), [])
    unavailable_service_identities = optional(list(string), [])
  })
  default = null
}
