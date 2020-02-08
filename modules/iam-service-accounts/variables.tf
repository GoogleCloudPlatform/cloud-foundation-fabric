/**
 * Copyright 2019 Google LLC
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

variable "generate_keys" {
  description = "Generate keys for service accounts."
  type        = bool
  default     = false
}

variable "names" {
  description = "Names of the service accounts to create."
  type        = list(string)
  default     = []
}

variable "prefix" {
  description = "Prefix applied to service account names."
  type        = string
  default     = ""
}

variable "project_id" {
  description = "Project id where service account will be created."
  type        = string
}

variable "iam_members" {
  description = "Map of member lists which are granted authoritative roles on the service accounts, keyed by role."
  type        = map(list(string))
  default     = {}
}

variable "iam_roles" {
  description = "List of authoritative roles granted on the service accounts."
  type        = list(string)
  default     = []
}

variable "iam_billing_roles" {
  description = "Project roles granted to all service accounts, by billing account id."
  type        = map(list(string))
  default     = {}
}

variable "iam_folder_roles" {
  description = "Project roles granted to all service accounts, by folder id."
  type        = map(list(string))
  default     = {}
}

variable "iam_organization_roles" {
  description = "Project roles granted to all service accounts, by organization id."
  type        = map(list(string))
  default     = {}
}

variable "iam_project_roles" {
  description = "Project roles granted to all service accounts, by project id."
  type        = map(list(string))
  default     = {}
}

variable "iam_storage_roles" {
  description = "Storage roles granted to all service accounts, by bucket name."
  type        = map(list(string))
  default     = {}
}
