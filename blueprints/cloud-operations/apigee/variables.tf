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

variable "datastore_name" {
  description = "Datastore."
  type        = string
  nullable    = false
  default     = "gcs"
}

variable "envgroups" {
  description = "Environment groups (NAME => [HOSTNAMES])."
  type        = map(list(string))
  nullable    = false
}

variable "environments" {
  description = "Environments."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    node_config = optional(object({
      min_node_count = optional(number)
      max_node_count = optional(number)
    }))
    iam       = optional(map(list(string)))
    envgroups = list(string)
  }))
  nullable = false
}

variable "instances" {
  description = "Instance."
  type = map(object({
    display_name         = optional(string)
    description          = optional(string)
    region               = string
    environments         = list(string)
    psa_ip_cidr_range    = string
    disk_encryption_key  = optional(string)
    consumer_accept_list = optional(list(string))
  }))
  nullable = false
}

variable "organization" {
  description = "Apigee organization."
  type = object({
    display_name            = optional(string, "Apigee organization created by tf module")
    description             = optional(string, "Apigee organization created by tf module")
    authorized_network      = optional(string, "vpc")
    runtime_type            = optional(string, "CLOUD")
    billing_type            = optional(string)
    database_encryption_key = optional(string)
    analytics_region        = optional(string, "europe-west1")
  })
  nullable = false
  default = {
  }
}

variable "path" {
  description = "Bucket path."
  type        = string
  default     = "/analytics"
  nullable    = false
}

variable "project_create" {
  description = "Parameters for the creation of the new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
  nullable    = false
}

variable "psc_config" {
  description = "PSC configuration."
  type        = map(string)
  nullable    = false
}

variable "vpc_create" {
  description = "Boolean flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}
