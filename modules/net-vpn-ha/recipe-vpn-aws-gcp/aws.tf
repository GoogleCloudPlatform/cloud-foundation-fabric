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

resource "aws_vpc" "vpc" {
  cidr_block = var.aws_vpc_cidr_block
}

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id          = aws_vpc.vpc.id
  amazon_side_asn = var.aws_asn
  tags = {
    Name = "vpn_gateway"
  }
}

resource "aws_customer_gateway" "customer_gateways" {
  count      = 2
  bgp_asn    = var.gcp_asn
  ip_address = module.gcp_vpn.gateway.vpn_interfaces[count.index].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "customer-gateway-${count.index}"
  }
}

resource "aws_vpn_gateway_attachment" "vpn_gateway_attachment" {
  vpc_id         = aws_vpc.vpc.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway.id
}

resource "aws_vpn_connection" "vpn_connections" {
  count                 = 2
  vpn_gateway_id        = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id   = aws_customer_gateway.customer_gateways[count.index].id
  type                  = "ipsec.1"
  tunnel1_preshared_key = var.shared_secret
  tunnel2_preshared_key = var.shared_secret
}


data "aws_route_table" "route_table" {
  count  = var.propagate_routes ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_vpn_gateway_route_propagation" "vpn_gateway_route_propagation" {
  count          = var.propagate_routes ? 1 : 0
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway.id
  route_table_id = data.aws_route_table.route_table[0].id
}

