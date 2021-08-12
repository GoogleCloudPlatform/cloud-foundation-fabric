# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "billing_account_id" {
  description = "Billing account id."
  type        = string
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

variable "project_names" {
  description = "Override this variable if you need non-standard names."
  type = object({
    datamart       = string
    dwh            = string
    landing        = string
    services       = string
    transformation = string
  })
  default = {
    datamart       = "datamart"
    dwh            = "datawh"
    landing        = "landing"
    services       = "services"
    transformation = "transformation"
  }
}

variable "root_node" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
}

variable "service_account_names" {
  description = "Override this variable if you need non-standard names."
  type = object({
    main = string
  })
  default = {
    main = "data-platform-main"
  }
}

variable "service_encryption_key_ids" {
  description = "Cloud KMS encryption key in {LOCATION => [KEY_URL]} format. Keys belong to existing project."
  type = object({
    multiregional = string
    global        = string
  })
  default = {
    multiregional = null
    global        = null
  }
}


variable "service_perimeter_standard" {
  description = "VPC Service control standard perimeter name in the form of 'accessPolicies/ACCESS_POLICY_NAME/servicePerimeters/PERIMETER_NAME'. All projects will be added to the perimeter in enforced mode."
  type        = string
  default     = null
}
