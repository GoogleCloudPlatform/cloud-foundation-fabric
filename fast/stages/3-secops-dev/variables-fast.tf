/**
 * Copyright 2024 Google LLC
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

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id = optional(string)
  })
  default = {}
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folder name => id mappings."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "secops_project_ids" {
  # tfdoc:variable:source 2-secops
  description = "SecOps Project IDs for each environment."
  type        = map(string)
  default     = null
}
