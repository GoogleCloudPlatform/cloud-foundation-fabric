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

variable "group" {
  type    = any
  default = null
}

variable "iam_members" {
  type    = map(list(string))
  default = {}
}

variable "iam_roles" {
  type    = list(string)
  default = []
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "use_instance_template" {
  type    = bool
  default = false
}

variable "service_account_create" {
  type    = bool
  default = false
}
