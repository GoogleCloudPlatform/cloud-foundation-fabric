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

variable "customer_id" {
  type        = string
  description = "Cloud Identity customer ID"
}

variable "domain" {
  type        = string
  description = "Domain to use"
}

variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "project_ids_full" {
  type        = map(string)
  description = "Project IDs"
}

variable "project_numbers" {
  type        = map(string)
  description = "Project numbers"
}

variable "environments" {
  type        = list(string)
  description = "List of environments"
}

variable "sa_groups" {
  type        = map(any)
  description = "Map of Service Account groups env per group"
}

variable "serverless_groups" {
  type        = map(string)
  description = "Map of serverless groups per environment"
}

variable "serverless_service_accounts" {
  type        = list(string)
  description = "List of serverless service accounts (Cloud Functions, Cloud Run)"
}

variable "only_add_project" {
  type        = bool
  description = "If this is set, don't make groups"
  default     = false
}

variable "all_groups" {
  type        = any
  description = "All groups in CI"
}
