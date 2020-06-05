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

variable "bucket_policy_only" {
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

variable "prefix" {
  type    = string
  default = null
}

variable "storage_class" {
  type    = string
  default = "MULTI_REGIONAL"
}

variable "versioning" {
  type    = map(bool)
  default = { bucket-a = true }
}
