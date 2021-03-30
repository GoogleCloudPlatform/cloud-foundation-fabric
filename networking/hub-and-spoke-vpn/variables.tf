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

variable "bgp_custom_advertisements" {
  description = "BGP custom advertisement IP CIDR ranges."
  type        = map(string)
  default = {
    hub-to-spoke-1 = "10.0.32.0/20"
    hub-to-spoke-2 = "10.0.16.0/20"
  }
}

variable "bgp_asn" {
  description = "BGP ASNs."
  type        = map(number)
  default = {
    hub     = 64513
    spoke-1 = 64514
    spoke-2 = 64515
  }
}

variable "bgp_interface_ranges" {
  description = "BGP interface IP CIDR ranges."
  type        = map(string)
  default = {
    spoke-1 = "169.254.1.0/30"
    spoke-2 = "169.254.1.4/30"
  }
}

variable "ip_ranges" {
  description = "IP CIDR ranges."
  type        = map(string)
  default = {
    hub-a     = "10.0.0.0/24"
    hub-b     = "10.0.8.0/24"
    spoke-1-a = "10.0.16.0/24"
    spoke-1-b = "10.0.24.0/24"
    spoke-2-a = "10.0.32.0/24"
    spoke-2-b = "10.0.40.0/24"
  }
}

variable "project_id" {
  description = "Project id for all resources."
  type        = string
}

variable "regions" {
  description = "VPC regions."
  type        = map(string)
  default = {
    a = "europe-west1"
    b = "europe-west2"
  }
}
