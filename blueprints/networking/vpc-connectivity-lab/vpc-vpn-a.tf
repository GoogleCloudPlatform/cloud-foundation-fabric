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

module "spoke-vpn-a-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vpn-a"
  mtu        = 1500
  subnets = [
    {
      name          = "vpn-a"
      region        = var.region
      ip_cidr_range = var.ip_ranges.vpn-a
    }
  ]
}

module "vpn-a-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.spoke-vpn-a-vpc.name
  default_rules_config = {
    admin_ranges = [var.ip_ranges.rfc1918_10]
  }
}

module "vpn-a-hub" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.spoke-vpn-a-vpc.self_link
  name       = "a-hub"
  peer_gateways = {
    default = { gcp = module.vpn-hub-a.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        (var.ip_ranges.vpn-a) = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}


