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

variable "monitoring_groups" {
  type        = map(string)
  description = "Map of monitoring groups per environment"
}

variable "monitoring_projects" {
  type        = map(string)
  description = "Map of monitoring host projects per environment"
}

variable "quota_project" {
  type        = string
  description = "Quota project for Stackdriver Accounts API"
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
