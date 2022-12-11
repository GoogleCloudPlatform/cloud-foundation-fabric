/**
 * Copyright 2022 Google LLC
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

locals {
  _peer_ranges = [
    for i, peer in var.peer_configs : cidrsubnet("169.254.0.0/16", 14, i)
  ]
  cloud_config = templatefile("${path.module}/assets/cloud-config.yaml", {
    asn              = var.asn
    external_address = var.external_address
    ip_range         = var.ip_range
    ipsec_vti = indent(6, templatefile("${path.module}/assets/ipsec-vti.sh", {
      peer_configs = local.peer_configs
    }))
    peer_configs = local.peer_configs
  })
  peer_configs = [
    for i, peer in var.peer_configs : merge(peer, {
      bgp_session = {
        asn = peer.bgp_session.asn
        local_address = (
          peer.bgp_session.local_address == null
          ? cidrhost(local._peer_ranges, i, 1)
          : peer.bgp_session.local_address
        )
        peer_address = (
          peer.bgp_session.local_address == null
          ? cidrhost(local._peer_ranges, i, 0)
          : peer.bgp_session.local_address
        )
      }
    })
  ]
}
