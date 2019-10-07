# Copyright 2019 Google LLC
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
variable "project_id" {
  description = "Project id to use for resources."
}
variable "prefix" {
  description = "Prefix for VPC names."
}
variable "hub_subnet_names" {
  description = "Hub VPC subnet names."
  default     = ["a", "b"]
}
variable "hub_subnet_regions" {
  description = "Hub subnet regions."
  default     = ["europe-west1", "europe-west2"]
}
variable "hub_subnet_cidr_ranges" {
  description = "Hub subnet IP CIDR ranges."
  default     = ["10.10.10.0/24", "10.10.20.0/24"]
}
variable "hub_bgp_asn" {
  description = "Hub BGP ASN."
  default     = 64515
}
variable "hub_custom_route_advertisement" {
  description = "Use custom route advertisement in hub routers to advertise all spoke subnets."
  default     = true
}
variable "spoke_1_subnet_names" {
  description = "Spoke 1 VPC subnet names."
  default     = ["a", "b"]
}
variable "spoke_1_subnet_regions" {
  description = "Spoke 1 subnet regions."
  default     = ["asia-east1", "asia-northeast1"]
}
variable "spoke_1_subnet_cidr_ranges" {
  description = "Spoke 1 subnet IP CIDR ranges."
  default     = ["10.20.10.0/24", "10.20.20.0/24"]
}
variable "spoke_1_bgp_asn" {
  description = "Spoke 1 BGP ASN."
  default     = 64516
}
variable "spoke_2_subnet_names" {
  description = "Spoke 2 VPC subnet names."
  default     = ["a", "b"]
}
variable "spoke_2_subnet_regions" {
  description = "Spoke 2 subnet regions."
  default     = ["us-west1", "us-west2"]
}
variable "spoke_2_subnet_cidr_ranges" {
  description = "Spoke 2 subnet IP CIDR ranges."
  default     = ["10.30.10.0/24", "10.30.20.0/24"]
}

variable "spoke_2_bgp_asn" {
  description = "Spoke 2 BGP ASN."
  default     = 64517
}