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

locals {
  hub_subnet_cidr_ranges     = (
    {
      for subnet in keys(var.hub_subnets)
      : var.hub_subnets[subnet]["ip_cidr_range"] => subnet
    }
  )
  spoke_1_subnet_cidr_ranges = (
    {
      for subnet in keys(var.spoke_1_subnets)
      : var.spoke_1_subnets[subnet]["ip_cidr_range"] => subnet
    }
  )
  spoke_2_subnet_cidr_ranges = (
    {
      for subnet in keys(var.spoke_2_subnets) 
      : var.spoke_2_subnets[subnet]["ip_cidr_range"] => subnet
    }
  )
  custom_routes_to_spokes = (
      merge(local.spoke_1_subnet_cidr_ranges, local.spoke_2_subnet_cidr_ranges)
  )
  all_subnet_cidrs = (
      concat(
          keys(local.hub_subnet_cidr_ranges),
          keys(local.spoke_1_subnet_cidr_ranges),
          keys(local.spoke_2_subnet_cidr_ranges),
          [var.on_prem_cidr_range]
      )
  )
}
