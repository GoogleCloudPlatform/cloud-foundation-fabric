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

variable "billing_account_id" {
  description = "Billing account id."
  type        = string
}

variable "billing_alert" {
  description = "Billing alert configuration."
  type = object({
    amount = number
    thresholds = object({
      current    = list(number)
      forecasted = list(number)
    })
    credit_treatment = string
  })
  default = null
}

variable "defaults" {
  description = "Project factory default values."
  type = object({
    billing_account_id = string
    billing_alert = object({
      amount = number
      thresholds = object({
        current    = list(number)
        forecasted = list(number)
      })
      credit_treatment = string
    })
    environment_dns_zone  = string
    essential_contacts    = list(string)
    labels                = map(string)
    notification_channels = list(string)
    shared_vpc_self_link  = string
    vpc_host_project      = string
  })
  default = null
}

variable "dns_zones" {
  description = "DNS private zones to create as child of var.defaults.environment_dns_zone."
  type        = list(string)
  default     = []
}

variable "essential_contacts" {
  description = "Email contacts to be used for billing and GCP notifications."
  type        = list(string)
  default     = []
}

variable "folder_id" {
  description = "Folder ID for the folder where the project will be created."
  type        = string
}

variable "group_iam" {
  description = "Custom IAM settings in group => [role] format."
  type        = map(list(string))
  default     = {}
}

variable "iam" {
  description = "Custom IAM settings in role => [principal] format."
  type        = map(list(string))
  default     = {}
}

variable "kms_service_agents" {
  description = "KMS IAM configuration in as service => [key]."
  type        = map(list(string))
  default     = {}
}

variable "labels" {
  description = "Labels to be assigned at project level."
  type        = map(string)
  default     = {}
}

variable "org_policies" {
  description = "Org-policy overrides at project level."
  type = object({
    policy_boolean = map(bool)
    policy_list = map(object({
      inherit_from_parent = bool
      suggested_value     = string
      status              = bool
      values              = list(string)
    }))
  })
  default = null
}

variable "prefix" {
  description = "Prefix used for the project id."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "service_accounts" {
  description = "Service accounts to be created, and roles to assign them."
  type        = map(list(string))
  default     = {}
}

variable "services" {
  description = "Services to be enabled for the project."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "service_identities_iam" {
  description = "Custom IAM settings for service identities in service => [role] format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "vpc" {
  description = "VPC configuration for the project."
  type = object({
    host_project = string
    gke_setup = object({
      enable_security_admin     = bool
      enable_host_service_agent = bool
    })
    subnets_iam = map(list(string))
  })
  default = null
}



