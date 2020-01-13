/**
 * Copyright 2019 Google LLC
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

variable "datasets" {
  description = "Map of datasets to create keyed by id. Labels and options can be null."
  type = map(object({
    description = string
    location    = string
    name        = string
    labels      = map(string)
  }))
}

variable "dataset_access" {
  description = "Optional map of dataset access rules by dataset id."
  type = map(list(object({
    role          = string
    identity_type = string
    identity      = any
  })))
  default = {}
}

variable "dataset_options" {
  description = "Optional map of dataset option by dataset id."
  type = map(object({
    default_table_expiration_ms     = number
    default_partition_expiration_ms = number
    delete_contents_on_destroy      = bool
  }))
  default = {}
}

variable "default_access" {
  description = "Access rules applied to all dataset if no specific ones are defined."
  type = list(object({
    role          = string
    identity_type = string
    identity      = any
  }))
  default = []
}

variable "default_labels" {
  description = "Labels set on all datasets."
  type        = map(string)
  default     = {}
}

variable "default_options" {
  description = "Options used for all dataset if no specific ones are defined."
  type = object({
    default_table_expiration_ms     = number
    default_partition_expiration_ms = number
    delete_contents_on_destroy      = bool
  })
  default = {
    default_table_expiration_ms     = null
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = false
  }
}

variable "kms_key" {
  description = "Self link of the KMS key that will be used to protect destination table."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Id of the project where datasets will be created."
  type        = string
}
