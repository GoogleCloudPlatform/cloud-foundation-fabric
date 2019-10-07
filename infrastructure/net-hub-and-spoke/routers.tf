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

resource "null_resource" "spoke-1-ranges-to-advertise" {
  count = length(local.spoke_1_subnet_cidr_ranges)
  triggers = {
    range = element(local.spoke_1_subnet_cidr_ranges, count.index)
  }
}

resource "null_resource" "spoke-2-ranges-to-advertise" {
  count = length(local.spoke_2_subnet_cidr_ranges)
  triggers = {
    range = element(local.spoke_2_subnet_cidr_ranges, count.index)
  }
}

resource "google_compute_router" "hub-to-spoke-1-custom" {
  count   = var.hub_custom_route_advertisement ? 1 : 0
  name    = "hub-to-spoke-1-custom"
  region  = element(local.hub_subnet_regions, 0)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn                  = var.hub_bgp_asn
    advertise_mode       = "CUSTOM"
    advertised_groups    = ["ALL_SUBNETS"]

    dynamic "advertised_ip_ranges" {
      for_each = [for trigger in null_resource.spoke-1-ranges-to-advertise.*.triggers: {
        range = trigger["range"]
      }]

      content {
        range = advertised_ip_ranges.value.range
      }
    }
  }
}

resource "google_compute_router" "hub-to-spoke-2-custom" {
  count   = var.hub_custom_route_advertisement ? 1 : 0
  name    = "hub-to-spoke-2-custom"
  region  = element(local.hub_subnet_regions, 1)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn                  = var.hub_bgp_asn
    advertise_mode       = "CUSTOM"
    advertised_groups    = ["ALL_SUBNETS"]
    dynamic "advertised_ip_ranges" {
      for_each = [for trigger in null_resource.spoke-2-ranges-to-advertise.*.triggers: {
        range = trigger["range"]
      }]

      content {
        range = advertised_ip_ranges.value.range
      }
    }
  }
}

resource "google_compute_router" "hub-to-spoke-1-default" {
  count   = var.hub_custom_route_advertisement ? 0 : 1
  name    = "hub-to-spoke-1-default"
  region  = element(local.hub_subnet_regions, 0)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn = var.hub_bgp_asn
  }
}
resource "google_compute_router" "hub-to-spoke-2-default" {
  count   = var.hub_custom_route_advertisement ? 0 : 1
  name    = "hub-to-spoke-2-default"
  region  = element(local.hub_subnet_regions, 1)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn = var.hub_bgp_asn
  }
}
resource "google_compute_router" "spoke-1" {
  name    = "spoke-1"
  region  = element(local.spoke_1_subnet_regions, 0)
  network = module.vpc-spoke-1.network_name
  project = var.spoke_1_project_id
  bgp {
    asn = var.spoke_1_bgp_asn
  }
}
resource "google_compute_router" "spoke-2" {
  name    = "spoke-2"
  region  = element(local.spoke_2_subnet_regions, 0)
  network = module.vpc-spoke-2.network_name
  project = var.spoke_2_project_id
  bgp {
    asn = var.spoke_2_bgp_asn
  }
}
