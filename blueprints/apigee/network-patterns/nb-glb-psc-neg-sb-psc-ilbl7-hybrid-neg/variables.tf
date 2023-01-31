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

variable "apigee_project_id" {
  description = "Project ID."
  type        = string
  nullable    = false
}

variable "apigee_proxy_only_subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range."
  type        = string
  default     = "10.2.1.0/24"
}

variable "apigee_psc_subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range."
  type        = string
  default     = "10.2.2.0/24"
}

variable "apigee_runtime_ip_cidr_range" {
  description = "Apigee PSA IP CIDR range."
  type        = string
  default     = "10.0.4.0/22"
}

variable "apigee_subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range."
  type        = string
  default     = "10.2.0.0/24"
}

variable "apigee_troubleshooting_ip_cidr_range" {
  description = "Apigee PSA IP CIDR range."
  type        = string
  default     = "10.1.0.0/28"
}

variable "billing_account_id" {
  description = "Parameters for the creation of the new project."
  type        = string
}

variable "hostname" {
  description = "Host name."
  type        = string
}

variable "onprem_project_id" {
  description = "Project ID."
  type        = string
  nullable    = false
}

variable "onprem_proxy_only_subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range."
  type        = string
  default     = "10.1.1.0/24"
}

variable "onprem_subnet_ip_cidr_range" {
  description = "Subnet IP CIDR range."
  type        = string
  default     = "10.1.0.0/24"
}

variable "parent" {
  description = "Parent (organizations/organizationID or folders/folderID)."
  type        = string
}

variable "region" {
  description = "Region."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone."
  type        = string
  default     = "europe-west1-c"
}
