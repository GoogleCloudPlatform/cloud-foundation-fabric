/**
 * Copyright 2026 Google LLC
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

variable "iam_principals" {
  # tfdoc:variable:source 0-org-setup
  description = "Org-level IAM principals."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "logging_sinks" {
  # tfdoc:variable:source 0-org-setup
  description = "Log sinks for the organization."
  type = map(object({
    project_id      = optional(string)
    writer_identity = string
    ## other available fields:
    # bigquery_options   = list(string)
    # description        = string
    # disabled           = bool
    # destination        = string
    # exclusions         = list(string)
    # filter             = string
    # id                 = string
    # include_children   = bool
    # intercept_children = bool
    # name               = string
    # org_id             = string
  }))
  default  = {}
  nullable = false
}

variable "organization" {
  # tfdoc:variable:source 0-org-setup
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
  nullable = false
}

variable "project_ids" {
  # tfdoc:variable:source 0-org-setup
  description = "Project IDs."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "project_numbers" {
  # tfdoc:variable:source 0-org-setup
  description = "Project numbers."
  type        = map(number)
  nullable    = false
  default     = {}
}

variable "root_node" {
  # tfdoc:variable:source 0-org-setup
  description = "Root node for the hierarchy, if running in tenant mode."
  type        = string
  default     = null
  validation {
    condition = (
      var.root_node == null ||
      startswith(coalesce(var.root_node, "-"), "folders/")
    )
    error_message = "Root node must be in folders/nnnnn format if specified."
  }
}

variable "service_accounts" {
  # tfdoc:variable:source 0-org-setup
  description = "Org-level service accounts."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "storage_buckets" {
  # tfdoc:variable:source 0-org-setup
  description = "Storage buckets created in the bootstrap stage."
  type        = map(string)
  nullable    = false
  default     = {}
}
