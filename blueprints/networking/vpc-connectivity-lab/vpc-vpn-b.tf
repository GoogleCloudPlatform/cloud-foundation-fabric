/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "spoke-vpn-b-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vpn-b"
  mtu        = 1500
  subnets = [
    {
      name          = "vpn-b"
      region        = var.region
      ip_cidr_range = var.ip_ranges.vpn-b
    }
  ]
}

module "vpn-b-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.spoke-vpn-b-vpc.name
  default_rules_config = {
    admin_ranges = [var.ip_ranges.rfc1918_10]
  }
}

module "vpn-b-hub" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.spoke-vpn-b-vpc.self_link
  name       = "b-hub"
  peer_gateways = {
    default = { gcp = module.vpn-hub-b.self_link }
  }
  router_config = {
    asn = 64515
    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        (var.ip_ranges.vpn-b) = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.5"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.6/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.5"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.6/30"
      vpn_gateway_interface = 1
    }
  }
}
