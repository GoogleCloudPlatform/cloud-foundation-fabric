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
module "vpc-hub" {
  source                = "../../modules/net-vpc-simple"
  prefix                = "${var.prefix}-hub"
  project_id            = "${var.project_id}"
  subnet_names          = ["${var.hub_subnet_names}"]
  subnet_regions        = ["${var.hub_subnet_regions}"]
  subnet_ip_cidr_ranges = ["${var.hub_subnet_cidr_ranges}"]
  routing_mode          = "GLOBAL"
}
module "vpc-spoke-1" {
  source                = "../../modules/net-vpc-simple"
  prefix                = "${var.prefix}-spoke-1"
  project_id            = "${var.project_id}"
  subnet_names          = ["${var.spoke_1_subnet_names}"]
  subnet_regions        = ["${var.spoke_1_subnet_regions}"]
  subnet_ip_cidr_ranges = ["${var.spoke_1_subnet_cidr_ranges}"]
  routing_mode          = "GLOBAL"
}
module "vpc-spoke-2" {
  source                = "../../modules/net-vpc-simple"
  prefix                = "${var.prefix}-spoke-2"
  project_id            = "${var.project_id}"
  subnet_names          = ["${var.spoke_2_subnet_names}"]
  subnet_regions        = ["${var.spoke_2_subnet_regions}"]
  subnet_ip_cidr_ranges = ["${var.spoke_2_subnet_cidr_ranges}"]
  routing_mode          = "GLOBAL"
}
module "firewall-hub" {
  source               = "../../modules/net-firewall"
  project_id           = "${var.project_id}"
  network              = "${module.vpc-hub.name}"
  admin_ranges_enabled = true
  admin_ranges         = ["${local.all_subnets}"]
}
module "firewall-spoke-1" {
  source               = "../../modules/net-firewall"
  project_id           = "${var.project_id}"
  network              = "${module.vpc-spoke-1.name}"
  admin_ranges_enabled = true
  admin_ranges         = ["${local.all_subnets}"]
}
module "firewall-spoke-2" {
  source               = "../../modules/net-firewall"
  project_id           = "${var.project_id}"
  network              = "${module.vpc-spoke-2.name}"
  admin_ranges_enabled = true
  admin_ranges         = ["${local.all_subnets}"]
}
module "vpn-hub-to-spoke-1" {
  source                   = "../../modules/net-vpn-dynamic"
  project_id               = "${var.project_id}"
  network                  = "${module.vpc-hub.name}"
  region                   = "${element(var.hub_subnet_regions, 0)}"
  prefix                   = "hub-to-spoke-1"
  peer_ip                  = "${module.vpn-spoke-1-to-hub.gateway_address}"
  bgp_cr_session_range     = "169.254.0.1/30"
  bgp_remote_session_range = "169.254.0.2"
  peer_asn                 = "${var.spoke_1_bgp_asn}"
  router                   = "${local.hub_to_spoke_1_router}"
}
module "vpn-hub-to-spoke-2" {
  source                   = "../../modules/net-vpn-dynamic"
  project_id               = "${var.project_id}"
  network                  = "${module.vpc-hub.name}"
  region                   = "${element(var.hub_subnet_regions, 1)}"
  prefix                   = "hub-to-spoke-2"
  peer_ip                  = "${module.vpn-spoke-2-to-hub.gateway_address}"
  bgp_cr_session_range     = "169.254.1.1/30"
  bgp_remote_session_range = "169.254.1.2"
  peer_asn                 = "${var.spoke_2_bgp_asn}"
  router                   = "${local.hub_to_spoke_2_router}"
}
module "vpn-spoke-1-to-hub" {
  source                   = "../../modules/net-vpn-dynamic"
  project_id               = "${var.project_id}"
  network                  = "${module.vpc-spoke-1.name}"
  region                   = "${element(var.spoke_1_subnet_regions, 0)}"
  prefix                   = "spoke-1-to-hub"
  shared_secret            = "${module.vpn-hub-to-spoke-1.shared_secret}"
  peer_ip                  = "${module.vpn-hub-to-spoke-1.gateway_address}"
  bgp_cr_session_range     = "169.254.0.2/30"
  bgp_remote_session_range = "169.254.0.1"
  peer_asn                 = "${var.hub_bgp_asn}"
  router                   = "${google_compute_router.spoke-1.name}"
}
module "vpn-spoke-2-to-hub" {
  source                   = "../../modules/net-vpn-dynamic"
  project_id               = "${var.project_id}"
  network                  = "${module.vpc-spoke-2.name}"
  region                   = "${element(var.spoke_2_subnet_regions, 0)}"
  prefix                   = "spoke-2-to-hub"
  shared_secret            = "${module.vpn-hub-to-spoke-2.shared_secret}"
  peer_ip                  = "${module.vpn-hub-to-spoke-2.gateway_address}"
  bgp_cr_session_range     = "169.254.1.2/30"
  bgp_remote_session_range = "169.254.1.1"
  peer_asn                 = "${var.hub_bgp_asn}"
  router                   = "${google_compute_router.spoke-2.name}"
}