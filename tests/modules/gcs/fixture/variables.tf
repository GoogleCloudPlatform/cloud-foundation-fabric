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

variable "uniform_bucket_level_access" {
  type    = bool
  default = false
}

variable "force_destroy" {
  type    = bool
  default = true
}

variable "iam" {
  type    = map(list(string))
  default = {}
}

variable "labels" {
  type    = map(string)
  default = { environment = "test" }
}

variable "logging_config" {
  type = object({
    log_bucket        = string
    log_object_prefix = string
  })
  default = {
    log_bucket        = "foo"
    log_object_prefix = null
  }
}

variable "prefix" {
  type    = string
  default = null
}

variable "project_id" {
  type    = string
  default = "my-project"
}

variable "retention_policy" {
  type = object({
    retention_period = number
    is_locked        = bool
  })
  default = {
    retention_period = 5
    is_locked        = false
  }
}

variable "storage_class" {
  type    = string
  default = "MULTI_REGIONAL"
}

variable "versioning" {
  type    = bool
  default = true
}
