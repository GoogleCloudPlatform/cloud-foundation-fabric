/**
 * Copyright 2023 Google LLC
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

variable "activated_policy_types" {
  description = "A list of policy types that are activated for this taxonomy."
  type        = list(string)
  default     = ["FINE_GRAINED_ACCESS_CONTROL"]
}

variable "description" {
  description = "Description of this taxonomy."
  type        = string
  default     = "Taxonomy - Terraform managed"
}

variable "location" {
  description = "Data Catalog Taxonomy location."
  type        = string
}

variable "name" {
  description = "Name of this taxonomy."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used to generate project id and name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "GCP project id."
  type        = string
}

variable "tags" {
  description = "List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format."
  type = map(object({
    description = optional(string)
    iam         = optional(map(list(string)), {})
  }))
  nullable = false
  default  = {}
}
