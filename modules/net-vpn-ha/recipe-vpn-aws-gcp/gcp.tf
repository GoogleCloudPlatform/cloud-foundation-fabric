/**
 * Copyright 2025 Google LLC
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

module "project" {
  source = "../../../modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = var._testing == null
    attributes      = var._testing
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
  ]
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vpc"
}

module "gcp_vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.gcp_region
  network    = module.vpc.self_link
  name       = "vpn"
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "FOUR_IPS_REDUNDANCY"
        interfaces = [
          aws_vpn_connection.vpn_connections[0].tunnel1_address,
          aws_vpn_connection.vpn_connections[0].tunnel2_address,
          aws_vpn_connection.vpn_connections[1].tunnel1_address,
          aws_vpn_connection.vpn_connections[1].tunnel2_address
        ] # on-prem router ip address
      }
    }
  }
  router_config = {
    asn = var.gcp_asn
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = aws_vpn_connection.vpn_connections[0].tunnel1_vgw_inside_address
        asn     = var.aws_asn
      }
      bgp_session_range               = "${aws_vpn_connection.vpn_connections[0].tunnel1_cgw_inside_address}/30"
      peer_external_gateway_interface = 0
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = aws_vpn_connection.vpn_connections[0].tunnel2_vgw_inside_address
        asn     = var.aws_asn
      }
      bgp_session_range               = "${aws_vpn_connection.vpn_connections[0].tunnel2_cgw_inside_address}/30"
      peer_external_gateway_interface = 1
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 0
    }
    remote-2 = {
      bgp_peer = {
        address = aws_vpn_connection.vpn_connections[1].tunnel1_vgw_inside_address
        asn     = var.aws_asn
      }
      bgp_session_range               = "${aws_vpn_connection.vpn_connections[1].tunnel1_cgw_inside_address}/30"
      peer_external_gateway_interface = 2
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 1
    }
    remote-3 = {
      bgp_peer = {
        address = aws_vpn_connection.vpn_connections[1].tunnel2_vgw_inside_address
        asn     = var.aws_asn
      }
      bgp_session_range               = "${aws_vpn_connection.vpn_connections[1].tunnel2_cgw_inside_address}/30"
      peer_external_gateway_interface = 3
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 1
    }
  }
}
