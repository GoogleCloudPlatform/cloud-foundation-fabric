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

# we need a separate variable as address will be dynamic in most cases
variable "endpoint_config" {
  description = "Map of endpoint attributes, keys are in service/endpoint format."
  type = map(object({
    address  = string
    port     = number
    metadata = map(string)
  }))
  default = {}
}

variable "iam_members" {
  description = "IAM members for each namespace role."
  type        = map(list(string))
  default     = {}
}

variable "iam_roles" {
  description = "IAM roles for the namespace."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Namespace location."
  type        = string
}

variable "name" {
  description = "Namespace name."
  type        = string
}

variable "project_id" {
  description = "Project used for resources."
  type        = string
}

variable "service_iam_members" {
  description = "IAM members for each service and role."
  type        = map(map(list(string)))
  default     = {}
}

variable "service_iam_roles" {
  description = "IAM roles for each service."
  type        = map(list(string))
  default     = {}
}

variable "services" {
  description = "Service configuration, using service names as keys."
  type = map(object({
    endpoints = list(string)
    metadata  = map(string)
  }))
  default = {}
}
