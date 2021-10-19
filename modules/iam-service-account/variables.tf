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

variable "description" {
  description = "Optional description."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name of the service account to create."
  type        = string
  default     = "Terraform-managed."
}

variable "generate_key" {
  description = "Generate a key for service account."
  type        = bool
  default     = false
}

variable "iam" {
  description = "IAM bindings on the service account in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_billing_roles" {
  description = "Project roles granted to the service account, by billing account id."
  type        = map(list(string))
  default     = {}
}

variable "iam_folder_roles" {
  description = "Project roles granted to the service account, by folder id."
  type        = map(list(string))
  default     = {}
}

variable "iam_organization_roles" {
  description = "Project roles granted to the service account, by organization id."
  type        = map(list(string))
  default     = {}
}

variable "iam_project_roles" {
  description = "Project roles granted to the service account, by project id."
  type        = map(list(string))
  default     = {}
}

variable "iam_storage_roles" {
  description = "Storage roles granted to the service account, by bucket name."
  type        = map(list(string))
  default     = {}
}

variable "name" {
  description = "Name of the service account to create."
  type        = string
}

variable "prefix" {
  description = "Prefix applied to service account names."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project id where service account will be created."
  type        = string
}

variable "service_account_create" {
  description = "Create service account. When set to false, uses a data source to reference an existing service account."
  type        = bool
  default     = true
}
