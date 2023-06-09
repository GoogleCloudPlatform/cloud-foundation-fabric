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

locals {
  nva_internal_cloud_config = <<-END
  #cloud-config
  runcmd:
  - iptables -P FORWARD ACCEPT
  - sysctl -w net.ipv4.ip_forward=1
  %{~for i, k in keys(local.nva_internal_nets)~}
  %{~if k != "dmz"~}
  - ip rule add from ${var.ip_ranges.subnets[k]} to 35.191.0.0/16 lookup ${i + 110}
  - ip rule add from ${var.ip_ranges.subnets[k]} to 130.211.0.0/22 lookup ${i + 110}
  - ip route add default via ${cidrhost(var.ip_ranges.subnets[k], 1)} dev eth${i} proto static onlink table ${i + 110}
  %{~endif~}
  %{~endfor~}
  %{~for r in var.ip_ranges.routes.onprem~}
  - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.inside, 1)} dev eth1 proto static onlink
  %{~endfor~}
  %{~for r in var.ip_ranges.routes.dev~}
  - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.trusted-dev, 1)} dev eth2 proto static onlink
  %{~endfor~}
  %{~for r in var.ip_ranges.routes.prod~}
  - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.trusted-prod, 1)} dev eth3 proto static onlink
  %{~endfor~}
  END
  nva_internal_nets = {
    dmz = {
      network    = module.hub-dmz-vpc.self_link
      subnetwork = module.hub-dmz-vpc.subnet_self_links["${var.region}/dmz"]
    },
    inside = {
      network    = module.hub-inside-vpc.self_link
      subnetwork = module.hub-inside-vpc.subnet_self_links["${var.region}/inside"]
    },
    trusted-dev = {
      network    = module.hub-trusted-dev-vpc.self_link
      subnetwork = module.hub-trusted-dev-vpc.subnet_self_links["${var.region}/trusted-dev"]
    }
    trusted-prod = {
      network    = module.hub-trusted-prod-vpc.self_link
      subnetwork = module.hub-trusted-prod-vpc.subnet_self_links["${var.region}/trusted-prod"]
    },
  }
}

module "hub-nva-internal" {
  source         = "../../../modules/compute-vm"
  for_each       = toset(local.nva_zones)
  project_id     = module.hub-project.project_id
  zone           = "${var.region}-b"
  name           = "nva-internal-${each.key}"
  instance_type  = "n2-standard-8"
  can_ip_forward = true
  network_interfaces = concat(
    # explicit ordering
    [
      for k in ["dmz", "inside", "trusted-dev", "trusted-prod"] :
      local.nva_internal_nets[k]
    ],
    [{
      network    = module.hub-management-vpc.self_link
      subnetwork = module.hub-management-vpc.subnet_self_links["${var.region}/mgmt"]
      }
    ]
  )
  metadata = {
    user-data              = local.nva_internal_cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable"
      type  = "pd-balanced"
      size  = 10
    }
  }
  tags  = ["nva-internal", "ssh"]
  group = { named_ports = { ssh = 22 } }

  # wait until the addresses are fully reserved to avoid this
  # VM from "stealing" one of those addresses
  depends_on = [module.hub-addresses]
}

module "hub-nva-internal-ilb" {
  source     = "../../../modules/net-ilb"
  for_each   = local.nva_internal_nets
  project_id = module.hub-project.project_id
  region     = var.region
  name       = "nva-internal-${each.key}"
  address    = module.hub-addresses.internal_addresses["nva-int-ilb-${each.key}"].address
  vpc_config = each.value
  backends = [
    for k, v in module.hub-nva-internal : {
      failover       = false
      group          = v.group.id
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    tcp = { port = "22" }
  }
}

