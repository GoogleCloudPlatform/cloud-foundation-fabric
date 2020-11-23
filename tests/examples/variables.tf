# Copyright 2020 Google LLC
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

variable "organization_id" {
  default = "organizations/1122334455"
}

variable "project_id" {
  default = "projects/project-id"
}

variable "billing_account_id" {
  default = "billing_account_id"
}

variable "bucket" {
  default = "bucket"
}

variable "region" {
  default = "region"
}

variable "zone" {
  default = "zone"
}

variable "vpc" {
  default = {
    name      = "vpc_name"
    self_link = "vpc_self_link"
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

variable "kms_key" {
  default = {
    self_link = "kms_key_self_link"
  }
}

variable "service_account" {
  default = {
    id        = "service_account_id"
    email     = "service_account_email"
    iam_email = "service_account_iam_email"
  }
}
