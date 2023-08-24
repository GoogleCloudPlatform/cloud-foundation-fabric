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

variable "addons_config" {
  description = "Addons configuration."
  type = object({
    advanced_api_ops    = optional(bool, false)
    api_security        = optional(bool, false)
    connectors_platform = optional(bool, false)
    integration         = optional(bool, false)
    monetization        = optional(bool, false)
  })
  default = null
}

variable "endpoint_attachments" {
  description = "Endpoint attachments."
  type = map(object({
    region             = string
    service_attachment = string
  }))
  default  = {}
  nullable = false
}

variable "envgroups" {
  description = "Environment groups (NAME => [HOSTNAMES])."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "environments" {
  description = "Environments."
  type = map(object({
    display_name    = optional(string)
    description     = optional(string, "Terraform-managed")
    deployment_type = optional(string)
    api_proxy_type  = optional(string)
    node_config = optional(object({
      min_node_count = optional(number)
      max_node_count = optional(number)
    }))
    iam       = optional(map(list(string)))
    envgroups = optional(list(string))
    regions   = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "instances" {
  description = "Instances ([REGION] => [INSTANCE])."
  type = map(object({
    display_name                  = optional(string)
    description                   = optional(string, "Terraform-managed")
    runtime_ip_cidr_range         = string
    troubleshooting_ip_cidr_range = string
    disk_encryption_key           = optional(string)
    consumer_accept_list          = optional(list(string))
    enable_nat                    = optional(bool, false)
  }))
  default  = {}
  nullable = false
}

variable "organization" {
  description = "Apigee organization. If set to null the organization must already exist."
  type = object({
    display_name            = optional(string)
    description             = optional(string, "Terraform-managed")
    authorized_network      = optional(string)
    runtime_type            = optional(string, "CLOUD")
    billing_type            = optional(string)
    database_encryption_key = optional(string)
    analytics_region        = optional(string, "europe-west1")
    retention               = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
}
