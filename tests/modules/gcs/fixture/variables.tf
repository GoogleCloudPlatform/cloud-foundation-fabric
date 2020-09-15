/**
 * Copyright 2020 Google LLC
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
  type    = map(bool)
  default = { bucket-a = false }
}

variable "force_destroy" {
  type    = map(bool)
  default = { bucket-a = true }
}

variable "iam_members" {
  type    = map(map(list(string)))
  default = null
}

variable "iam_roles" {
  type    = map(list(string))
  default = null
}

variable "labels" {
  type    = map(string)
  default = { environment = "test" }
}

variable "logging_config" {
  type = map(object({
    log_bucket        = string
    log_object_prefix = string
  }))
  default = {
    bucket-a = { log_bucket = "foo", log_object_prefix = null }
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

variable "retention_policies" {
  type = map(object({
    retention_period = number
    is_locked        = bool
  }))
  default = {
    bucket-b = { retention_period = 5, is_locked = false }
  }
}

variable "storage_class" {
  type    = string
  default = "MULTI_REGIONAL"
}

variable "versioning" {
  type    = map(bool)
  default = { bucket-a = true }
}
