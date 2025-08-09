/**
 * Copyright 2025 Google LLC
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

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_billing_roles" {
  description = "Billing account roles granted to this service account, by billing account id. Non-authoritative."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_by_principals_additive" {
  description = "Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam_bindings_additive` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_folder_roles" {
  description = "Folder roles granted to this service account, by folder id. Non-authoritative."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_organization_roles" {
  description = "Organization roles granted to this service account, by organization id. Non-authoritative."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_project_roles" {
  description = "Project roles granted to this service account, by project id."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_sa_roles" {
  description = "Service account roles granted to this service account, by service account name."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_storage_roles" {
  description = "Storage roles granted to this service account, by bucket name."
  type        = map(list(string))
  default     = {}
  nullable    = false
}
