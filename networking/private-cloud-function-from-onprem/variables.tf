/**
 * Copyright 2021 Google LLC
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

variable "region" {
  description = "Region where the resources will be created."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone where the test VM will be created."
  type        = string
  default     = "europe-west1-b"
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
  default     = null
}

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "projects_id" {
  description = "ID of the projects used in this solution."
  type   = object({
    onprem   = string
    function = string
  })
}

variable "create_projects" {
  description = "Whether need to create the projects."
  type        = bool
  default     = true
}

variable "root_node" {
  description = "Root folder or organization under which the projects will be created."
  type        = string
}

variable "cloud_function_gcs_bucket" {
  description = "Google Storage Bucket used as staging location for the Cloud Function source code."
  type        = string
}

variable "ip_ranges" {
  description = "IP ranges used for the VPCs."
  type = object({
    onprem = string
    hub    = string
  })
  default = {
    onprem = "10.0.1.0/24",
    hub    = "10.0.2.0/24"
  }
}

variable "psc_endpoint" {
  description = "IP used for the Private Service Connect endpoint, it must not overlap with the hub_ip_range."
  type    = string
  default = "10.100.100.100"
}
