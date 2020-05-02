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

variable "access" {
  description = "Dataset access rules keyed by role, valid identity types are `domain`, `group_by_email`, `special_group` and `user_by_email`. Mode can be controlled via the `access_authoritative` variable."
  type = map(list(object({
    identity_type = string
    identity      = string
  })))
  default = {}
}

variable "access_authoritative" {
  description = "Use authoritative access instead of additive."
  type        = bool
  default     = false
}

variable "access_views" {
  description = "Dataset access rules for views. Mode can be controlled via the `access_authoritative` variable."
  type = list(object({
    project_id = string
    dataset_id = string
    table_id   = string
  }))
  default = []
}

variable "encryption_key" {
  description = "Self link of the KMS key that will be used to protect destination table."
  type        = string
  default     = null
}

variable "labels" {
  description = "Dataset labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Dataset location."
  type        = string
  default     = "EU"
}

variable "friendly_name" {
  description = "Dataset friendly name."
  type        = string
  default     = null
}

variable "id" {
  description = "Dataset id."
  type        = string
}

variable "options" {
  description = "Dataset options."
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

variable "project_id" {
  description = "Id of the project where datasets will be created."
  type        = string
}

variable "tables" {
  description = "Table definitions. Options and partitioning default to null. Partitioning can only use `range` or `time`, set the unused one to null."
  type = map(object({
    friendly_name = string
    labels        = map(string)
    options = object({
      clustering      = list(string)
      encryption_key  = string
      expiration_time = number
    })
    partitioning = object({
      field = string
      range = object({
        end      = number
        interval = number
        start    = number
      })
      time = object({
        expiration_ms = number
        type          = string
      })
    })
    schema = string
  }))
  default = {}
}

variable "views" {
  description = "View definitions."
  type = map(object({
    friendly_name  = string
    labels         = map(string)
    query          = string
    use_legacy_sql = bool
  }))
  default = {}
}
