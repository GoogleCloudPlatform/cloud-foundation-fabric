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

variable "custom_domain" {
  description = "Custom domain for the Load Balancer."
  type        = string
  default     = "service-b.acme.org"
}

variable "image_configs" {
  description = "Container images for Cloud Run services."
  type = object({
    svc_a = string
    svc_b = optional(string, "us-docker.pkg.dev/cloudrun/container/hello")
  })
  nullable = false
}

variable "ip_configs" {
  description = "IP ranges or IPs used by the VPC."
  type        = map(string)
  default = {
    subnet_main       = "10.0.1.0/24"
    subnet_proxy      = "10.10.0.0/24"
    subnet_vpc_access = "10.10.10.0/28"
    subnet_vpc_direct = "10.8.0.0/26"
    psc_addr          = "10.0.0.100"
  }
}

variable "prefix" {
  description = "Prefix used for project names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_configs" {
  description = "Projects to use, one project or host and service projects."
  type = map(object({
    billing_account_id = optional(string)
    parent             = optional(string)
    project_id         = optional(string)
  }))
  default = {
    main    = {} # Or host project
    service = {}
  }
  nullable = false
  validation {
    condition     = var.project_configs.main.project_id != null
    error_message = "At least the main project ID is needed."
  }
}

variable "region" {
  description = "Cloud region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}
