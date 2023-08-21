/**
 * Copyright 2023 Google LLC
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

variable "ignore_folders" {
  description = "A list of folder IDs or numbers to be excluded from the output, all the subfolders and projects are excluded from the output regardless of the include_projects variable."
  type        = list(string)
  default     = []
  # example exlusing a folder
  # ignore_folders = [
  #   "folders/0123456789",
  #   "2345678901"
  # ]
}

variable "ignore_projects" {
  description = "A list of project IDs, numbers or prefixes to exclude matching projects from the module output."
  type        = list(string)
  default     = []
  # example
  #ignore_projects = [
  #  "dev-proj-1",
  #  "uat-proj-2",
  #  "0123456789",
  #  "prd-proj-*"
  #]
}

variable "include_projects" {
  description = "A list of project IDs/numbers to include to the output if some of them are excluded by `ignore_projects` wildcard entries."
  type        = list(string)
  default     = []
  # example excluding all the projects starting with "prf-" except "prd-123457"
  #ignore_projects = [
  #  "prd-*"
  #]
  #include_projects = [
  #  "prd-123457",
  #  "0123456789"
  #]
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  validation {
    condition     = can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "query" {
  description = "A string query as defined in the [Query Syntax](https://cloud.google.com/asset-inventory/docs/query-syntax)."
  type        = string
  default     = "state:ACTIVE"
}
