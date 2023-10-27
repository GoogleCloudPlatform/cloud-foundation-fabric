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
    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
    iam_bindings_additive = optional(map(object({
      role   = string
      member = string
    })), {})
    envgroups = optional(list(string), [])
  }))
  default  = {}
  nullable = false
}

variable "instances" {
  description = "Instances ([REGION] => [INSTANCE])."
  type = map(object({
    name                          = optional(string)
    display_name                  = optional(string)
    description                   = optional(string, "Terraform-managed")
    runtime_ip_cidr_range         = optional(string)
    troubleshooting_ip_cidr_range = optional(string)
    disk_encryption_key           = optional(string)
    consumer_accept_list          = optional(list(string))
    enable_nat                    = optional(bool, false)
    environments                  = optional(list(string), [])
  }))
  validation {
    condition = alltrue([
      for k, v in var.instances :
      # has troubleshooting_ip => has runtime_ip
      v.runtime_ip_cidr_range != null || v.troubleshooting_ip_cidr_range == null
    ])
    error_message = "Using a troubleshooting range requires specifying a runtime range too."
  }
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
    disable_vpc_peering     = optional(bool, false)
  })
  validation {
    condition = var.organization == null || (
      try(var.organization.runtime_type, null) == "CLOUD" || !try(var.organization.disable_vpc_peering, false)
    )
    error_message = "Disabling the VPC peering can only be done in organization using the CLOUD runtime."
  }
  validation {
    condition = var.organization == null || (
      try(var.organization.authorized_network, null) == null || !try(var.organization.disable_vpc_peering, false)
    )
    error_message = "Disabling the VPC peering is mutually exclusive with authorized_network."
  }
  default = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
}
