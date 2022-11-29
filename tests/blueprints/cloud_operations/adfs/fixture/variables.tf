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

variable "project_create" {
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = {
    billing_account_id = "12345-12345-12345"
    parent             = "folders/123456789"
  }
}

variable "project_id" {
  type    = string
  default = "my-project"
}

variable "prefix" {
  type    = string
  default = "test"
}

variable "network_config" {
  type = object({
    network = string
    subnet  = string
  })
  default = null
}

variable "ad_dns_domain_name" {
  type    = string
  default = "example.com"
}

variable "adfs_dns_domain_name" {
  type    = string
  default = "adfs.example.com"
}

variable "disk_size" {
  type    = number
  default = 50
}

variable "disk_type" {
  type    = string
  default = "pd-ssd"
}

variable "image" {
  type    = string
  default = "projects/windows-cloud/global/images/family/windows-2022"
}

variable "instance_type" {
  type    = string
  default = "n1-standard-2"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-c"
}

variable "ad_ip_cidr_block" {
  type    = string
  default = "10.0.0.0/24"
}

variable "subnet_ip_cidr_block" {
  type    = string
  default = "10.0.1.0/28"
}
