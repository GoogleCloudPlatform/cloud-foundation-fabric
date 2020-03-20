/**
 * Copyright 2020 Google LLC
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

variable "organization_id" {
  description = "Organization id."
  type        = string
}

variable "root_node" {
  description = "Root node in folders/folder_id or organizations/org_id format."
  type        = string
}

variable "prefix" {
  description = "Prefix used for GCS bucket names."
  type        = string
}

variable "environments" {
  description = "Unit environments short names."
  type        = map(string)
  default = {
    dev  = "development",
    test = "Testing",
    prod = "Production"
  }
}

variable "automation_project_id" {
  description = "Project id used for automation service accounts."
  type        = string
}

variable "billing_account_id" {
  description = "Country billing account account."
  type        = string
}

variable "name" {
  description = "Top folder name."
  type        = string
}

variable "short_name" {
  description = "Short name."
  type        = string
}

variable "gcs_defaults" {
  description = "Defaults use for the state GCS buckets."
  type        = map(string)
  default = {
    location      = "EU"
    storage_class = "MULTI_REGIONAL"
  }
}

variable "iam_roles" {
  description = "IAM roles applied on the unit folder."
  type        = list(string)
}

variable "iam_members" {
  description = "IAM members for roles applied on the unit folder."
  type        = map(list(string))
}

variable "iam_enviroment_roles" {
  description = "IAM roles granted to service accounts on the environment sub-folders."
  type        = list(string)
  default = [
    "roles/compute.networkAdmin",
    "roles/owner",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
  ]
}

variable "service_account_keys" {
  description = "Generate and store service account keys in the state file."
  type        = bool
  default     = false
}

variable "iam_xpn_config" {
  description = "Control granting Shared VPC creation roles to service accounts. Target the root node by default."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}

variable "iam_billing_config" {
  description = "Control granting billing user role to service accounts. Target the billing account by default."
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}
