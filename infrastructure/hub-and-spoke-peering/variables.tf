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

variable "ip_ranges" {
  description = "IP CIDR ranges."
  type        = map(string)
  default = {
    hub     = "10.0.0.0/24"
    spoke-1 = "10.0.16.0/24"
    spoke-2 = "10.0.32.0/24"
  }
}

variable "ip_secondary_ranges" {
  description = "Secondary IP CIDR ranges."
  type        = map(string)
  default = {
    spoke-2-pods     = "10.128.0.0/18"
    spoke-2-services = "172.16.0.0/24"
  }
}

variable "private_service_ranges" {
  description = "Private service IP CIDR ranges."
  type        = map(string)
  default = {
    spoke-2-cluster-1 = "192.168.0.0/28"
  }
}

variable "project_id" {
  description = "Project id for all resources."
  type        = string
}

variable "region" {
  description = "VPC region."
  type        = string
  default     = "europe-west1"
}
