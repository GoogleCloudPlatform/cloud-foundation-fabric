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

variable "iam" {
  type    = map(list(string))
  default = {}
}

variable "policy_boolean" {
  type    = map(bool)
  default = {}
}

variable "policy_list" {
  type = map(object({
    inherit_from_parent = bool
    suggested_value     = string
    status              = bool
    values              = list(string)
  }))
  default = {}
}

variable "firewall_policies" {
  type = map(map(object({
    description             = string
    direction               = string
    action                  = string
    priority                = number
    ranges                  = list(string)
    ports                   = map(list(string))
    target_service_accounts = list(string)
    target_resources        = list(string)
    logging                 = bool
  })))
  default = {}
}

variable "firewall_policy_attachments" {
  type    = map(string)
  default = {}
}

variable "logging_sinks" {
  type = map(object({
    destination      = string
    type             = string
    filter           = string
    iam              = bool
    include_children = bool
    exclusions       = map(string)
  }))
  default = {}
}

variable "logging_exclusions" {
  type    = map(string)
  default = {}
}
