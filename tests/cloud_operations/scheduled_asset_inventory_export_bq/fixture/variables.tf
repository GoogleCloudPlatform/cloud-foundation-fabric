# Copyright 2022 Google LLC
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

variable "billing_account" {
  type    = string
  default = "1234-ABCD-1234"
}

variable "cai_config" {
  type = object({
    bq_dataset         = string
    bq_table           = string
    bq_table_overwrite = bool
    target_node        = string
  })
  default = {
    bq_dataset         = "my-dataset"
    bq_table           = "my_table"
    bq_table_overwrite = "true"
    target_node        = "organization/1234567890"
  }
}

variable "cai_gcs_export" {
  type    = bool
  default = true
}

variable "file_config" {
  type = object({
    bucket     = string
    filename   = string
    format     = string
    bq_dataset = string
    bq_table   = string
  })
  default = {
    bucket     = "my-bucket"
    filename   = "my-folder/myfile.json"
    format     = "NEWLINE_DELIMITED_JSON"
    bq_dataset = "my-dataset"
    bq_table   = "my_table"
  }
}


variable "project_create" {
  type    = bool
  default = true
}

variable "project_id" {
  type    = string
  default = "project-1"
}
