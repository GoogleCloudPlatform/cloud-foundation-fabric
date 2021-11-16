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

variable "domain" {
  type        = string
  description = "Domain to use"
}

variable "customer_id" {
  type        = string
  description = "Cloud Identity customer ID"
}

variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "project_ids_full" {
  type        = map(string)
  description = "Project IDs (full)"
}

variable "project_numbers" {
  type        = map(string)
  description = "Project numbers"
}

variable "environments" {
  type        = list(string)
  description = "Environments"
}

variable "group_format" {
  type        = string
  default     = "%project%-serviceaccounts-%env%"
  description = "Project SA group naming format"
}

variable "add_to_shared_vpc_group" {
  type        = bool
  default     = false
  description = "Add project SA group to Shared VPC group"
}

variable "shared_vpc_groups" {
  type        = map(string)
  description = "Shared VPC groups (one for each environment)"
}

variable "service_account" {
  type        = string
  description = "Terraform provisioner service account"
}

variable "service_accounts" {
  type        = list(string)
  description = "Service accounts to add to project SA group"
}

variable "only_add_permissions" {
  type        = bool
  description = "Don't create groups, just add permissions (groups have to exist)"
  default     = false
}

variable "api_service_accounts" {
  type        = map(any)
  description = "API service accounts"
}

variable "activated_apis" {
  type        = list(string)
  description = "Activated APIs"
}

variable "all_groups" {
  type        = any
  description = "All groups in CI"
}
