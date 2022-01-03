/**
 * Copyright 2022 Google LLC
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

variable "automation_project_id" {
  description = "Project id used for automation service accounts."
  type        = string
}

variable "billing_account_id" {
  description = "Country billing account account."
  type        = string
}

variable "environments" {
  description = "Unit environments short names."
  type        = map(string)
  default = {
    non-prod = "Non production"
    prod     = "Production"
  }
}

variable "gcs_defaults" {
  description = "Defaults use for the state GCS buckets."
  type        = map(string)
  default = {
    location      = "EU"
    storage_class = "MULTI_REGIONAL"
  }
}

variable "iam" {
  description = "IAM bindings for the top-level folder in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_billing_config" {
  description = "Grant billing user role to service accounts, defaults to granting on the billing account."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}

variable "iam_enviroment_roles" {
  description = "IAM roles granted to the environment service account on the environment sub-folder."
  type        = list(string)
  default = [
    "roles/compute.networkAdmin",
    "roles/owner",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
  ]
}

variable "iam_xpn_config" {
  description = "Grant Shared VPC creation roles to service accounts, defaults to granting at folder level."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}

variable "name" {
  description = "Top folder name."
  type        = string
}

variable "organization_id" {
  description = "Organization id in organizations/nnnnnn format."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for GCS bucket names to ensure uniqueness."
  type        = string
  default     = null
}

variable "root_node" {
  description = "Root node in folders/folder_id or organizations/org_id format."
  type        = string
}

variable "service_account_keys" {
  description = "Generate and store service account keys in the state file."
  type        = bool
  default     = false
}

variable "short_name" {
  description = "Short name used as GCS bucket and service account prefixes, do not use capital letters or spaces."
  type        = string
}
