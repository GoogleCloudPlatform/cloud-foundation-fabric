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

variable "billing_account_id" {
  type = string
}

variable "gitlab_config" {
  type = object({
    hostname = optional(string, "gitlab.example.com")
  })
  default = {}
}

variable "host_project_ids" {
  type = object({
    dev-spoke-0 = string
  })
}

variable "prefix" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west8"
}

variable "root_node" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_self_links" {
  type = object({
    dev-spoke-0 = map(string)
  })
}

variable "vpc_self_links" {
  type = object({
    dev-spoke-0 = string
  })
}
