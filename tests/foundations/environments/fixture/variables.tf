# Copyright 2021 Google LLC
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
  type    = string
  default = "1234-5678-9012"
}

variable "environments" {
  type    = list(string)
  default = ["test", "prod"]
}

variable "iam_audit_viewers" {
  type    = list(string)
  default = ["user:audit-1@example.org", "user:audit2@example.org"]
}

variable "iam_shared_owners" {
  type    = list(string)
  default = ["user:shared-1@example.org", "user:shared-2@example.org"]
}

variable "iam_terraform_owners" {
  type    = list(string)
  default = ["user:tf-1@example.org", "user:tf-2@example.org"]
}

variable "iam_xpn_config" {
  type = object({
    grant      = bool
    target_org = bool
  })
  default = {
    grant      = true
    target_org = false
  }
}

variable "organization_id" {
  type    = string
  default = ""
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
  default     = "test"
}

variable "root_node" {
  description = "Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'."
  type        = string
  default     = "folders/1234567890"
}
