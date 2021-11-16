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

variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "project_ids_full" {
  type        = map(string)
  description = "Project IDs"
}

variable "environments" {
  type        = list(string)
  description = "List of environments"
}

variable "project_permissions" {
  type        = list(string)
  description = "List of project permissions"
}

variable "extra_permissions" {
  type        = map(any)
  description = "List of extra per-folder per-environment project permissions"
}

variable "group" {
  type        = string
  description = "Group to give privileges to"
}

variable "group_format" {
  type        = string
  description = "Group format"
}

variable "domain" {
  type        = string
  description = "Domain"
}

variable "service_accounts" {
  type        = map(any)
  description = "Service accounts"
}

variable "compute_sa_permissions" {
  type        = list(string)
  description = "Compute SA permissions"
}

variable "project_sa_permissions" {
  type        = list(string)
  description = "Project SA permissions"
}

variable "additional_roles" {
  type        = list(string)
  description = "Additional sets of IAM roles for groups"
}

variable "additional_roles_config" {
  type        = map(any)
  description = "Additional IAM roles config"
}

variable "additional_iam_roles" {
  type        = list(string)
  description = "Additional IAM roles for groups"
}
