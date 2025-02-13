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

variable "vpc_connector_create" {
  description = "Populate this to create a Serverless VPC Access connector."
  type = object({
    ip_cidr_range = optional(string)
    machine_type  = optional(string)
    name          = optional(string)
    network       = optional(string)
    instances = optional(object({
      max = optional(number)
      min = optional(number)
      }), {}
    )
    throughput = optional(object({
      max = optional(number)
      min = optional(number)
      }), {}
    )
    subnet = optional(object({
      name       = optional(string)
      project_id = optional(string)
    }), {})
  })
  default = null
}
