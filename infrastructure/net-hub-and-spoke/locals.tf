
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

locals {
  hub_subnet_regions         = [for subnet in var.hub_subnets : subnet["subnet_region"]]
  spoke_1_subnet_regions     = [for subnet in var.spoke_1_subnets : subnet["subnet_region"]]
  spoke_2_subnet_regions     = [for subnet in var.spoke_2_subnets : subnet["subnet_region"]]
  hub_subnet_cidr_ranges     = [for subnet in var.hub_subnets : subnet["subnet_ip"]]
  spoke_1_subnet_cidr_ranges = [for subnet in var.spoke_1_subnets : subnet["subnet_ip"]]
  spoke_2_subnet_cidr_ranges = [for subnet in var.spoke_2_subnets : subnet["subnet_ip"]]
  all_subnet_cidrs           = concat(local.hub_subnet_cidr_ranges, local.spoke_1_subnet_cidr_ranges, local.spoke_2_subnet_cidr_ranges)
  hub_to_spoke_1_router = var.hub_custom_route_advertisement ? element(concat(google_compute_router.hub-to-spoke-1-custom.*.name, list("")), 0) : element(concat(google_compute_router.hub-to-spoke-1-default.*.name, list("")), 0)
  hub_to_spoke_2_router = var.hub_custom_route_advertisement ? element(concat(google_compute_router.hub-to-spoke-2-custom.*.name, list("")), 0) : element(concat(google_compute_router.hub-to-spoke-2-default.*.name, list("")), 0)
}
