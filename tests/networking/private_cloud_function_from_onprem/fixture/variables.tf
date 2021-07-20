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
  default = "ABCDE-12345-ABCDE"
}

variable "projects_id" {
  type   = object({
    onprem   = string
    function = string
  })
  default = {
    onprem   = "onprem-project-id"
    function = "function-project-id"
  }
}

variable "root_node" {
  type    = string
  default = "organizations/0123456789"
}

variable cloud_function_gcs_bucket {
  type    = string
  default = "stanging-gcs-bucket"
}