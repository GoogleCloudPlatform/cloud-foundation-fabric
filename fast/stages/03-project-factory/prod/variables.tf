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

#TODO: tfdoc annotations

variable "billing_account_id" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id."
  type        = string
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data."
  type        = string
  default     = "data/projects"
}

variable "environment_dns_zone" {
  # tfdoc:variable:source 02-networking
  description = "DNS zone suffix for environment."
  type        = string
  default     = null
}

variable "defaults_file" {
  description = "Relative path for the file storing the project factory configuration."
  type        = string
  default     = "data/defaults.yaml"
}

variable "shared_vpc_self_link" {
  # tfdoc:variable:source 02-networking
  description = "Self link for the shared VPC."
  type        = string
  default     = null
}

variable "vpc_host_project" {
  # tfdoc:variable:source 02-networking
  description = "Host project for the shared VPC."
  type        = string
  default     = null
}
