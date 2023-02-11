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

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "projects_create" {
  description = "Parameters for the creation of the new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "region_configs" {
  description = "The primary and secondary region parameters."
  type = object({
    r1 = object({
      region_name = string
      zone        = string
    })
    r2 = object({
      region_name = string
      zone        = string
    })
  })
  default = {
    r1 = {
      region_name = "europe-west1"
      zone        = "europe-west1-b"
    }
    r2 = {
      region_name = "europe-west2"
      zone        = "europe-west2-b"
    }
  }
}

variable "test_vms_behind_ilb" {
  description = "Whether there should be an ILB L4 in front of the test VMs in the spoke."
  type        = string
  default     = false
}

variable "vpc_landing_untrusted_config" {
  description = "The configuration of the landing untrusted VPC"
  type = object({
    r1_cidr = string
    r2_cidr = string
  })
  default = {
    r1_cidr = "192.168.1.0/24",
    r2_cidr = "192.168.2.0/24"
  }
}

variable "vpc_landing_trusted_config" {
  description = "The configuration of the landing trusted VPC"
  type = object({
    r1_cidr = string
    r2_cidr = string
  })
  default = {
    r1_cidr = "192.168.11.0/24",
    r2_cidr = "192.168.22.0/24"
  }
}

variable "vpc_spoke_config" {
  description = "The configuration of the spoke-01 VPC"
  type = object({
    r1_cidr = string
    r2_cidr = string
  })
  default = {
    r1_cidr = "192.168.101.0/24",
    r2_cidr = "192.168.102.0/24"
  }
}
