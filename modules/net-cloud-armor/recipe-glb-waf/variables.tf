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

variable "geo_allowlist" {
  description = "ISO 3166-1 alpha-2 region codes allowed to reach the application. Leave empty to allow all regions."
  type        = list(string)
  default     = []
  nullable    = false
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
  default     = "armor-glb"
  nullable    = false
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "rate_limit" {
  description = "Per-client IP rate limit enforced on the application backend."
  type = object({
    count            = optional(number, 100)
    interval_sec     = optional(number, 60)
    ban_duration_sec = optional(number, 300)
  })
  default  = {}
  nullable = false
}

variable "region" {
  description = "Region where the Cloud Run service and bucket are deployed."
  type        = string
}

variable "waf_config" {
  description = "Preconfigured WAF rule sets evaluated on the application backend, and whether they run in preview mode."
  type = object({
    preview = optional(bool, true)
    rule_sets = optional(list(string), [
      "sqli-v33-stable", "xss-v33-stable", "lfi-v33-stable", "rce-v33-stable"
    ])
    sensitivity = optional(number, 1)
  })
  default  = {}
  nullable = false
}
