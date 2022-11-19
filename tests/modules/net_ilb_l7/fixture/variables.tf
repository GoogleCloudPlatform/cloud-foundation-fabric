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
  description = "Optional IP address used for the forwarding rule."
  type        = string
  default     = null
}

variable "backend_service_configs" {
  type    = any
  default = {}
}

variable "description" {
  type    = string
  default = "Terraform managed."
}

variable "group_configs" {
  type    = any
  default = {}
}

variable "health_check_configs" {
  type = any
  default = {
    default = {
      http = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "neg_configs" {
  type    = any
  default = {}
}

variable "network_tier_premium" {
  type    = bool
  default = true
}

variable "ports" {
  type    = list(string)
  default = null
}

variable "protocol" {
  type    = string
  default = "HTTP"
}

variable "ssl_certificates" {
  type    = any
  default = {}
}

variable "urlmap_config" {
  type = any
  default = {
    default_service = "default"
  }
}
