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

variable "_test_service_project" {
  type    = bool
  default = false
}

variable "name" {
  type    = string
  default = "my-project"
}

variable "billing_account" {
  type    = string
  default = "12345-12345-12345"
}

variable "auto_create_network" {
  type    = bool
  default = false
}

variable "custom_roles" {
  type    = map(list(string))
  default = {}
}

variable "iam" {
  type    = map(list(string))
  default = {}
}

variable "iam_additive" {
  type    = map(list(string))
  default = {}
}

variable "iam_additive_members" {
  type    = map(list(string))
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "lien_reason" {
  type    = string
  default = ""
}

variable "org_policies" {
  type    = any
  default = {}
}

variable "org_policies_data_path" {
  type    = any
  default = null
}

variable "oslogin" {
  type    = bool
  default = false
}

variable "oslogin_admins" {
  type    = list(string)
  default = []
}

variable "oslogin_users" {
  type    = list(string)
  default = []
}

variable "parent" {
  type    = string
  default = null
}

variable "prefix" {
  type    = string
  default = null
}

variable "service_encryption_key_ids" {
  type    = map(list(string))
  default = {}
}

variable "services" {
  type    = list(string)
  default = []
}

variable "logging_sinks" {
  type    = any
  default = {}
}

variable "logging_exclusions" {
  type    = map(string)
  default = {}
}

variable "shared_vpc_host_config" {
  type = object({
    enabled          = bool
    service_projects = list(string)
  })
  default = {
    enabled = true
    service_projects = [
      "my-service-project-1",
      "my-service-project-2"
    ]
  }
}
