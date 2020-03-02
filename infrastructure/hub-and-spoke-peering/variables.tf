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

variable "hub_project_id" {
  description = "Hub Project id. Same project can be used for hub and spokes."
  type        = string
}

variable "spoke_1_project_id" {
  description = "Spoke 1 Project id. Same project can be used for hub and spokes."
  type        = string
}

variable "spoke_2_project_id" {
  description = "Spoke 2 Project id. Same project can be used for hub and spokes."
  type        = string
}

variable "hub_subnets" {
  description = "Hub VPC subnets configuration."
  type = map(object({
    ip_cidr_range = string
    region        = string
  }))
  default = {
    hub-subnet-a = {
      ip_cidr_range = "10.10.10.0/24"
      region        = "europe-west1"
    }
    hub-subnet-b = {
      ip_cidr_range = "10.10.20.0/24"
      region        = "europe-west2"
    }
  }
}

variable "spoke_1_subnets" {
  description = "Spoke 1 VPC subnets configuration."
  type = map(object({
    ip_cidr_range = string
    region        = string
  }))
  default = {
    spoke-1-subnet-a = {
      ip_cidr_range = "10.20.10.0/24"
      region        = "europe-west1"
    }
    spoke-1-subnet-b = {
      ip_cidr_range = "10.20.20.0/24"
      region        = "europe-west2"
    }
  }
}

variable "spoke_2_subnets" {
  description = "Spoke 2 VPC subnets configuration."
  type = map(object({
    ip_cidr_range = string
    region        = string
  }))
  default = {
    spoke-2-subnet-a = {
      ip_cidr_range = "10.30.10.0/24"
      region        = "europe-west1"
    }
    spoke-2-subnet-b = {
      ip_cidr_range = "10.30.20.0/24"
      region        = "europe-west2"
    }
  }
}

variable "private_dns_zone_name" {
  description = "Private DNS Zone Name."
  type        = string
  default     = "gcp-local"
}

variable "private_dns_zone_domain" {
  description = "Private DNS Zone Domain."
  type        = string
  default     = "gcp.local."
}

variable "forwarding_dns_zone_name" {
  description = "Forwarding DNS Zone Name."
  type        = string
  default     = "on-prem-local"
}

variable "forwarding_dns_zone_domain" {
  description = "Forwarding DNS Zone Domain."
  type        = string
  default     = "on-prem.local."
}

variable "forwarding_zone_server_addresses" {
  description = "Forwarding DNS Zone Server Addresses"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}
