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

# tflint-ignore: terraform_naming_convention
variable "_testing" {
  description = "Populate this variable to avoid triggering the data source."
  type = object({
    name             = string
    number           = number
    services_enabled = optional(list(string), [])
  })
  default = null
}

variable "invoker_members" {
  description = "Identities allowed to invoke the Cloud Run service. Override when the organization restricts allUsers via domain restricted sharing."
  type        = list(string)
  default     = ["allUsers"]
  nullable    = false
}

variable "name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "armor-ralb"
  nullable    = false
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "region" {
  description = "Region where all resources are deployed."
  type        = string
}

variable "trusted_ranges" {
  description = "IP ranges exempted from WAF inspection, e.g. corporate egress ranges."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "vpc_config" {
  description = "VPC configuration."
  type = object({
    subnet_cidr     = optional(string, "10.0.0.0/24")
    proxy_only_cidr = optional(string, "10.0.1.0/24")
  })
  default  = {}
  nullable = false
}

variable "waf_config" {
  description = "Preconfigured WAF rule sets evaluated on the backend services, and whether they run in preview mode."
  type = object({
    preview = optional(bool, true)
    rule_sets = optional(list(string), [
      "sqli-v33-stable", "xss-v33-stable"
    ])
    sensitivity = optional(number, 1)
  })
  default  = {}
  nullable = false
}
