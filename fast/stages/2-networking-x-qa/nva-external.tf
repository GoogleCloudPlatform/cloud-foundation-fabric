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
  for_each       = toset(["a"]) # , "b"])
  project_id     = module.hub-project.project_id
  zone           = "${var.region}-b"
  name           = "nva-external-${each.key}"
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
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 10.0.0.0/8 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 172.16.0.0/12 lookup 110
    - ip rule add from ${var.ip_ranges.subnets.dmz} to 192.168.0.0/16 lookup 110
    - ip route add default via ${cidrhost(var.ip_ranges.subnets.dmz, 1)} dev eth1 proto static onlink table 110
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
  tags  = ["nva", "ssh"]
  group = { named_ports = { ssh = 22 } }
  # depends_on = [module.hub-addresses]
}

module "hub-nva-external-dmz" {
  source     = "../../../modules/net-ilb"
  project_id = module.hub-project.project_id
  region     = var.region
  name       = "nva-external-dmz"
  address    = module.hub-addresses.internal_addresses["nva-external-dmz"].address
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
