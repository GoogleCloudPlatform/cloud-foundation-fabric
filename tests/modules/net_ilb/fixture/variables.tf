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

variable "address" {
  type    = string
  default = null
}

variable "backend_service_config" {
  description = "Backend service level configuration."
  type        = any
  default     = {}
}

variable "backends" {
  type    = any
  default = []
}

variable "description" {
  type    = string
  default = "Terraform managed."
}

variable "global_access" {
  type    = bool
  default = null
}

variable "group_configs" {
  type    = any
  default = {}
}

variable "ports" {
  type    = list(string)
  default = null
}

variable "protocol" {
  type    = string
  default = "TCP"
}

variable "service_label" {
  type    = string
  default = null
}
