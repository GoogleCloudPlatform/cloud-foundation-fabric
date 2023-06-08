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
  #   interfaces = {
  #     1 = module.office-vpc-prod.subnet_ips["${var.region}/prod-default"]
  #     2 = module.office-vpc-preprod.subnet_ips["${var.region}/preprod-default"]
  #     3 = module.office-vpc-dev.subnet_ips["${var.region}/dev-default"]
  #     4 = module.office-vpc-test.subnet_ips["${var.region}/test-default"]
  #     5 = module.office-vpc-ss.subnet_ips["${var.region}/ss-default"]
  #     6 = module.core-vpc-f5.subnet_ips["${var.region}/f5-default"]
  #   }
  nva_cloud_config = ""
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
}

module "nva" {
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
      addresses = {
        internal = module.hub-addresses.internal_addresses["nva-external-untrusted"].address
        external = null
      }
    },
    {
      network    = module.hub-dmz-vpc.self_link
      subnetwork = module.hub-dmz-vpc.subnet_self_links["${var.region}/dmz"]
      addresses = {
        internal = module.hub-addresses.internal_addresses["nva-external-dmz"].address
        external = null
      }
    }
  ]
  metadata = {
    user-data              = local.nva_cloud_config
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

# locals {
#   ilb_configs = {
#     dmz = {
#       network = module.core-vpc-dmz.network.id
#       subnet  = module.core-vpc-dmz.subnet_self_links["${var.region}/dmz-default"]
#     }
#     f5 = {
#       network = module.core-vpc-f5.network.id
#       subnet  = module.core-vpc-f5.subnet_self_links["${var.region}/f5-default"]
#     }
#     prod = {
#       network = module.office-vpc-prod.network.id
#       subnet  = module.office-vpc-prod.subnet_self_links["${var.region}/prod-default"]
#     }
#     preprod = {
#       network = module.office-vpc-preprod.network.id
#       subnet  = module.office-vpc-preprod.subnet_self_links["${var.region}/preprod-default"]
#     }
#     dev = {
#       network = module.office-vpc-dev.network.id
#       subnet  = module.office-vpc-dev.subnet_self_links["${var.region}/dev-default"]
#     }
#     test = {
#       network = module.office-vpc-test.network.id
#       subnet  = module.office-vpc-test.subnet_self_links["${var.region}/test-default"]
#     }
#     ss = {
#       network = module.office-vpc-ss.network.id
#       subnet  = module.office-vpc-ss.subnet_self_links["${var.region}/ss-default"]
#     }
#   }
# }

# module "core-ilb" {
#   source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-ilb?ref=v23.0.0&depth=1"
#   for_each      = local.ilb_configs
#   project_id    = module.core-project.project_id
#   region        = var.region
#   name          = each.key
#   address       = module.core-addresses.internal_addresses["nva-${each.key}"].address
#   service_label = var.prefix
#   global_access = true
#   vpc_config = {
#     network    = each.value.network
#     subnetwork = each.value.subnet
#   }
#   backends = [
#     for k, v in module.nva : {
#       failover       = false
#       group          = v.group.id
#       balancing_mode = "CONNECTION"
#     }
#   ]
#   health_check_config = {
#     tcp = { port = "22" }
#   }
# }
