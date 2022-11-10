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

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "name" {
  description = "Project name and id suffix."
  type        = string
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "europe-west1"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "service_attachment_id" {
  description = "PSC producer service attachment id."
  type        = string
}
