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

# locals {
#   interfaces = {
#     1 = module.office-vpc-prod.subnet_ips["${var.region}/prod-default"]
#     2 = module.office-vpc-preprod.subnet_ips["${var.region}/preprod-default"]
#     3 = module.office-vpc-dev.subnet_ips["${var.region}/dev-default"]
#     4 = module.office-vpc-test.subnet_ips["${var.region}/test-default"]
#     5 = module.office-vpc-ss.subnet_ips["${var.region}/ss-default"]
#     6 = module.core-vpc-f5.subnet_ips["${var.region}/f5-default"]
#   }
#   nva_cloud_config = <<-END
#   #cloud-config
#   runcmd:
#   - iptables -P FORWARD ACCEPT
#   - sysctl -w net.ipv4.ip_forward=1
#   %{for k, v in local.interfaces}
#   - ip rule add from ${v} to 35.191.0.0/16 lookup ${k + 110}
#   - ip rule add from ${v} to 130.211.0.0/22 lookup ${k + 110}
#   - ip route add default via ${cidrhost(v, 1)} dev eth${k} proto static onlink table ${k + 110}
#   %{endfor}
#   - ip rule add from ${var.ip_ranges.office-internal} to ${var.ip_ranges.apigee-runtime} lookup 115
#   END
# }

locals {
  nva_internal_nets = {
    dmz = {
      network    = module.hub-dmz-vpc.self_link
      subnetwork = module.hub-dmz-vpc.subnet_self_links["${var.region}/dmz"]
    },
    inside = {
      network    = module.hub-inside-vpc.self_link
      subnetwork = module.hub-inside-vpc.subnet_self_links["${var.region}/inside"]
    },
    trusted-prod = {
      network    = module.hub-trusted-prod-vpc.self_link
      subnetwork = module.hub-trusted-prod-vpc.subnet_self_links["${var.region}/trusted-prod"]
    },
    trusted-dev = {
      network    = module.hub-trusted-dev-vpc.self_link
      subnetwork = module.hub-trusted-dev-vpc.subnet_self_links["${var.region}/trusted-dev"]
    }
  }
}

module "hub-nva-internal" {
  source         = "../../../modules/compute-vm"
  for_each       = toset(["a"]) # , "b"])
  project_id     = module.hub-project.project_id
  zone           = "${var.region}-b"
  name           = "nva-internal-${each.key}"
  instance_type  = "custom-6-4"
  can_ip_forward = true
  network_interfaces = concat(
    [for k, v in local.nva_internal_nets : v],
    [{
      network    = module.hub-management-vpc.self_link
      subnetwork = module.hub-management-vpc.subnet_self_links["${var.region}/mgmt"]
      }
    ]
  )
  metadata = {
    user-data              = <<-END
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
  tags  = ["nva-internal", "ssh"]
  group = { named_ports = { ssh = 22 } }
  # depends_on = [module.hub-addresses]
}

module "hub-nva-internal-ilb" {
  source     = "../../../modules/net-ilb"
  for_each   = local.nva_internal_nets
  project_id = module.hub-project.project_id
  region     = var.region
  name       = "nva-internal-dmz"
  address    = module.hub-addresses.internal_addresses["nva-internal-${each.key}"].address
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

