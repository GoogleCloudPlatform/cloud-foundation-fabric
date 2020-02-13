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

variable "administrators" {
  description = "List of IAM-style identities that will manage the playground."
  type        = list(string)
  default     = []
}

variable "billing_account" {
  description = "Billing account id on which ot assign billing roles."
  type        = string
}

variable "name" {
  description = "Playground folder name."
  type        = string
}

variable "billing_roles" {
  description = "List of IAM roles granted to administrators on the billing account."
  type        = list(string)
  default = [
    "roles/billing.user"
  ]
}

variable "folder_roles" {
  description = "List of IAM roles granted to administrators on folder."
  type        = list(string)
  default = [
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectIamAdmin",
    "roles/compute.xpnAdmin"
  ]
}

variable "organization_id" {
  description = "Top-level organization id on which to apply roles, format is the numeric id."
  type        = number
}

variable "organization_roles" {
  description = "List of IAM roles granted to administrators on the organization."
  type        = list(string)
  default = [
    "roles/browser",
    "roles/resourcemanager.organizationViewer"
  ]
}

variable "parent" {
  description = "Parent organization or folder, in organizations/nnn or folders/nnn format."
  type        = string
}
