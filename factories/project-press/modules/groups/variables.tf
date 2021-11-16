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

variable "environments" {
  type        = list(string)
  description = "Environments"
}

variable "folder" {
  type        = string
  description = "Folder"
}

variable "group_format" {
  type        = string
  default     = "%project%-%group%-%env%"
  description = "Project naming format"
}

variable "groups" {
  type        = map(list(string))
  description = "Groups to provision"
}

variable "groups_permissions" {
  type        = map(any)
  description = "Group permissions"
}

variable "main_group" {
  type        = string
  description = "Group that will contain all groups"
}

variable "owner" {
  type        = string
  description = "Owner"
}

variable "owners" {
  type        = list(string)
  description = "Owners"
}

variable "owner_group" {
  type        = string
  description = "Group that will contain the owner"
}

variable "shared_vpc_groups" {
  type        = map(string)
  description = "Shared VPC groups (one for each environment)"
}

variable "service_accounts" {
  type        = map(any)
  description = "Service accounts"
}

variable "only_add_permissions" {
  type        = bool
  description = "Don't create groups, just add permissions (groups have to exist)"
  default     = false
}

variable "additional_roles" {
  type        = map(list(string))
  description = "Additional sets of IAM roles for groups"
}

variable "additional_roles_config" {
  type        = map(any)
  description = "Additional IAM roles config"
}

variable "additional_iam_roles" {
  type        = map(list(string))
  description = "Additional IAM roles for groups"
}

variable "all_groups" {
  type        = any
  description = "All groups in CI"
}
