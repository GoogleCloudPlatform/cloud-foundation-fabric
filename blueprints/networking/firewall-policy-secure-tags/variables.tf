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

variable "identities" {
  type = object({
    admin = string
    dev   = string
    prod  = string
  })
  default = {
    admin = "admin@mydomain.go"
    dev   = "dev@mydomain.go"
    prod  = "prod@mydomain.go"
  }
}

variable "instance_type" {
  type    = string
  default = "e2-standard-2"
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
  validation {
    condition     = can(regex("^organizations/[0-9]+", var.organization_id))
    error_message = "The organization_id must in the form organizations/nnn."
  }
}

variable "prefix" {
  description = "Prefix to use for resource names."
  type        = string
}

variable "project_config" {
  description = "When referncing existing projects, the project configuration."
  type = object({
    billing_account = optional(string) # when new projects get created
    id              = optional(string) # when existing projects are referenced
    parent          = optional(string) # when new projects get created
  })
}

variable "project_create" {
  description = "Whether to automatically create a project."
  type        = bool
  default     = false
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR to assign to the subnet."
  type        = string
  default     = "192.168.0.0/24"
}

variable "zone" {
  description = "Zone where resources will be created."
  type        = string
}
