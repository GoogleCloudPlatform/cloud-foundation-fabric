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
  default     = "012345-67890A-BCDEF0"
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data."
  type        = string
  default     = "./projects/"
}

variable "environment_dns_zone" {
  description = "DNS zone suffix for environment."
  type        = string
  default     = "prod.gcp.example.com"
}

variable "defaults_file" {
  description = "Relative path for the file storing the project factory configuration."
  type        = string
  default     = "./defaults.yaml"
}

variable "service_accounts" {
  description = "Service accounts to be created, and roles assigned them on the project."
  type        = map(list(string))
  default     = {}
}

variable "service_accounts_iam" {
  description = "IAM bindings on service account resources. Format is KEY => {ROLE => [MEMBERS]}"
  type        = map(map(list(string)))
  default     = {}
  nullable    = false
}

variable "shared_vpc_self_link" {
  description = "Self link for the shared VPC."
  type        = string
  default     = "self-link"
}

variable "vpc_host_project" {
  description = "Host project for the shared VPC."
  type        = string
  default     = "host-project"
}
