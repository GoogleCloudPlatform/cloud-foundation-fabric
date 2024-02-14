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

# tfdoc:file:description Serverless Connector variables.

variable "serverless_connector_config" {
  description = "VPC Access Serverless Connectors configuration."
  type = object({
    dev-primary = object({
      ip_cidr_range = optional(string, "10.255.255.128/28")
      machine_type  = optional(string)
      instances = optional(object({
        max = optional(number)
        min = optional(number)
      }), {})
      throughput = optional(object({
        max = optional(number)
        min = optional(number)
      }), {})
    })
    prod-primary = object({
      ip_cidr_range = optional(string, "10.255.255.0/28")
      machine_type  = optional(string)
      instances = optional(object({
        max = optional(number)
        min = optional(number)
      }), {})
      throughput = optional(object({
        max = optional(number)
        min = optional(number)
      }), {})
    })
  })
  default = {
    dev-primary  = {}
    prod-primary = {}
  }
  nullable = false
}
