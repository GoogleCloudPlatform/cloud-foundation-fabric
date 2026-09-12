/**
 * Copyright 2026 Google LLC
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


variable "location" {
  type    = string
  default = "europe-west8"
}

variable "network_config" {
  type = object({
    build_psa_range = optional(string, "/24")
    vpc_self_link   = string
  })
  default = {
    vpc_self_link = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
}

variable "prefix" {
  type    = string
  default = "test-0"
}

variable "project_ids" {
  type = object({
    build = string
    ssm   = string
  })
  default = {
    build = "tf-playground-dev-build-pool-0"
    ssm   = "foo"
  }
}
