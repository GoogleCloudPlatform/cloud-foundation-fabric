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

variable "project_ids_full" {
  type        = map(string)
  description = "Project IDs"
}

variable "environments" {
  type        = list(string)
  description = "List of environments"
}

variable "project_groups" {
  type        = map(any)
  description = "Map of project groups env per group"
}

variable "sa_groups" {
  type        = map(any)
  description = "Map of service account groups env per group"
}

variable "service_accounts" {
  type        = list(any)
  description = "Service accounts to provision"
}

variable "service_account_roles" {
  type        = map(any)
  description = "Service accounts to provision"
}

variable "only_add_permissions" {
  type        = bool
  description = "Don't create groups, just add permissions (groups have to exist)"
  default     = false
}

