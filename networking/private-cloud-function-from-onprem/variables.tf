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

###############################################################################
#                                  variables                                  #
###############################################################################

variable "region" {
  type    = string
  default = "europe-west1"
  # Region where the resources will be created
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
  # Zone where the test VM will be created
}

variable "billing_account_id" {
  type    = string
  # Your billing account ID, in the format "XXXXXX-XXXXXX-XXXXXX"
}

variable "onprem_project_id" {
  type    = string
  # Project ID used as "on-prem" environment
}

variable "gcp_project_id" {
  type    = string
  # Project ID used as "GCP" environment
}

variable "create_projects" {
  type    = bool
  default = true
  # Whether terraform will create the projects (false if the projects already exist)
}

variable "root_id" {
  type    = string
  # Root folder or organization under which the projects will be created, in the format "folders/XXXXXXXXXXXX" or "organizations/XXXXXXXXXXXX"
}

variable "cloud_function_gcs_bucket" {
  type    = string
  # Google Storage Bucket used as staging location for the Cloud Function source code
}

variable "onprem_ip_range" {
  type    = string
  default = "10.0.1.0/24"
  # IP ranged used for the "on-prem" VPC
}

variable "gcp_ip_range" {
  type    = string
  default = "10.0.2.0/24"
  # IP ranged used for the "GCP" VPC
}

variable "psc_endpoint" {
  type    = string
  default = "10.100.100.100"
  # IP used for the Private Service Connect endpoint, it must not overlap with the gcp_ip_range
}
