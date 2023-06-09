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

module "hub-nva-external" {
  source         = "../../../modules/compute-vm"
  for_each       = toset(local.nva_zones)
  project_id     = module.hub-project.project_id
  zone           = "${var.region}-b"
  name           = "nva-ext-${each.key}"
  instance_type  = "n2-standard-2"
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.hub-untrusted-vpc.self_link
      subnetwork = module.hub-untrusted-vpc.subnet_self_links["${var.region}/untrusted"]
    },
    {
      network    = module.hub-dmz-vpc.self_link
      subnetwork = module.hub-dmz-vpc.subnet_self_links["${var.region}/dmz"]
    }
  ]
  metadata = {
    user-data              = <<-END
    #cloud-config
    runcmd:
    - iptables -P FORWARD ACCEPT
    - sysctl -w net.ipv4.ip_forward=1
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 35.191.0.0/16 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 130.211.0.0/22 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 10.0.0.0/8 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 172.16.0.0/12 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 192.168.0.0/16 lookup 110
    - ip route add default via ${cidrhost(var.ip_ranges.subnets.dmz, 1)} dev eth1 proto static onlink table 110
    %{~for r in var.ip_ranges.routes.onprem~}
    # change to rule?
    - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.inside, 1)} dev eth1 proto static onlink
    %{~endfor~}
    %{~for r in var.ip_ranges.routes.dev~}
    # change to rule?
    - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.inside, 1)} dev eth1 proto static onlink
    %{~endfor~}
    %{~for r in var.ip_ranges.routes.prod~}
    # change to rule?
    - ip route add ${r} via ${cidrhost(var.ip_ranges.subnets.inside, 1)} dev eth1 proto static onlink
    %{~endfor~}
    - iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
    END
    google-logging-enabled = true
  }
  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable"
      type  = "pd-balanced"
      size  = 10
    }
  }
  tags  = ["nva-ext", "ssh"]
  group = { named_ports = { ssh = 22 } }
  # give the address module a chance to reserve addresses first
  depends_on = [module.hub-addresses]
}

module "hub-nva-ext-ilb-dmz" {
  source     = "../../../modules/net-ilb"
  project_id = module.hub-project.project_id
  region     = var.region
  name       = "nva-ext-ilb-dmz"
  address    = module.hub-addresses.internal_addresses["nva-ext-ilb-dmz"].address
  vpc_config = {
    network    = module.hub-dmz-vpc.id
    subnetwork = module.hub-dmz-vpc.subnets["${var.region}/dmz"].id
  }
  backends = [
    for k, v in module.hub-nva-external : {
      failover       = false
      group          = v.group.id
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    tcp = { port = "22" }
  }
}
