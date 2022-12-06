# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# common variables used for examples

variable "bucket" {
  default = "bucket"
}

variable "billing_account_id" {
  default = "billing_account_id"
}

variable "kms_key" {
  default = {
    self_link = "kms_key_self_link"
  }
}

variable "organization_id" {
  default = "organizations/1122334455"
}

variable "folder_id" {
  default = "folders/1122334455"
}

variable "prefix" {
  default = "test"
}

variable "project_id" {
  default = "project-id"
}

variable "region" {
  default = "region"
}

variable "service_account" {
  default = {
    id        = "service_account_id"
    email     = "service_account_email"
    iam_email = "service_account_iam_email"
  }
}

variable "subnet" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "vpc" {
  default = {
    name      = "vpc_name"
    self_link = "projects/xxx/global/networks/aaa"
  }
}

variable "vpc1" {
  default = {
    name      = "vpc_name"
    self_link = "projects/xxx/global/networks/bbb"
  }
}

variable "vpc2" {
  default = {
    name      = "vpc2_name"
    self_link = "projects/xxx/global/networks/ccc"
  }
}

variable "zone" {
  default = "zone"
}
