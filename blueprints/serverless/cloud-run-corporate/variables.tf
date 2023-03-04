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

variable "access_policy" {
  description = "VPC SC access policy, if it exists."
  type        = string
  default     = null
}

variable "access_policy_create" {
  description = "Parameters for the creation of a VPC SC access policy."
  type = object({
    parent = string
    title  = string
  })
  default = null
}

variable "custom_domain" {
  description = "Custom domain for the Load Balancer."
  type        = string
  default     = null
}

variable "image" {
  description = "Container image to deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "ingress_settings" {
  description = "Ingress traffic sources allowed to call the service."
  type        = string
  default     = "internal"
}

variable "ip_ranges" {
  description = "IPs or IP ranges used by VPCs."
  type        = map(map(string))
  default = {
    main = {
      subnet       = "10.0.1.0/24"
      subnet_proxy = "10.10.0.0/24"
      psc_addr     = "10.0.0.100"
    }
    onprem = {
      subnet = "172.16.1.0/24"
    }
    prj1 = {
      subnet   = "10.0.2.0/24"
      psc_addr = "10.0.0.200"
    }
  }
}

variable "prj_main_create" {
  description = "Parameters for the creation of the main project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "prj_main_id" {
  description = "Main Project ID."
  type        = string
}

variable "prj_onprem_create" {
  description = "Parameters for the creation of an 'onprem' project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "prj_onprem_id" {
  description = "Onprem Project ID."
  type        = string
  default     = null
}

variable "prj_prj1_create" {
  description = "Parameters for the creation of project 1."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "prj_prj1_id" {
  description = "Project 1 ID."
  type        = string
  default     = null
}

variable "prj_svc1_create" {
  description = "Parameters for the creation of service project 1."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "prj_svc1_id" {
  description = "Service Project 1 ID."
  type        = string
  default     = null
}

variable "region" {
  description = "Cloud region where resource will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "tf_identity" {
  description = "Terraform identity to include in VPC SC perimeter."
  type        = string
  default     = null
}
