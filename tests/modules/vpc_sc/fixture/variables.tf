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

variable "access_levels" {
  type     = any
  default  = {}
  nullable = false
}

variable "access_policy" {
  type = string
}

variable "access_policy_create" {
  type    = any
  default = null
}

variable "egress_policies" {
  type     = any
  default  = {}
  nullable = false
}

variable "ingress_policies" {
  type     = any
  default  = {}
  nullable = false
}

variable "service_perimeters_bridge" {
  type    = any
  default = {}
}

variable "service_perimeters_regular" {
  type     = any
  default  = {}
  nullable = false
}
