/**
 * Copyright 2024 Google LLC
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

variable "image" {
  description = "Container image to use."
  type        = string
  nullable    = false
  default     = "redis:6.2"
}

variable "tenants" {
  description = "Chronicle forwarders tenants config."
  type = map(object({
    chronicle_forwarder_image = optional(string, "cf_production_stable")
    chronicle_region          = string
    tenant_id                 = string
    namespace                 = string
    network_config = optional(object({
      expose_service_attachment = optional(bool, false)
      load_balancer_ports       = optional(list(string), null)
    }), {})
    forwarder_config = object({
      config_file_content = optional(string)
      customer_id         = optional(string)
      collector_id        = optional(string)
      secret_key          = optional(string)
      tls_config = optional(object({
        required = optional(bool, false)
        cert_pub = optional(string)
        cert_key = optional(string)
      }), { required = false })
    })
  }))
  default = {}
}