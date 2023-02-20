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
  nva_locality = {for item in flatten([
    for priority, region in var.regions : [
      for zone in var.zones: {
        "${region}-${zone}" = {
          region  = region
          trigram = local.region_shortnames[region]
          zone    = zone
        }
      }
    ]
  ]): keys(item)[0] => values(item)[0]}

  # routing_config should be aligned to the NVA network interfaces - i.e.
  # local.routing_config[0] sets up the first interface, and so on.
  routing_config = [
    {
      name = "untrusted"
      routes = [
        var.custom_adv.gcp_landing_untrusted_primary,
        var.custom_adv.gcp_landing_untrusted_secondary,
      ]
    },
    {
      name = "trusted"
      routes = [
        var.custom_adv.rfc_1918_10,
        var.custom_adv.rfc_1918_172,
        var.custom_adv.rfc_1918_192,
        var.custom_adv.gcp_landing_trusted_primary,
        var.custom_adv.gcp_landing_trusted_secondary
      ]
    },
  ]
}

# NVA configs
module "nva-bgp-cloud-config" {
  for_each             = local.nva_locality
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_bgp           = true
  enable_health_checks = true
  network_interfaces   = local.routing_config
  frr_config           = "./bgp-files/${each.value.trigram}${each.value.zone}"
}

resource "google_compute_address" "nva_static_ip_untrusted" {
  for_each     = local.nva_locality
  name         = "nva-ip-untrusted-${each.value.trigram}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.trigram}"]
  address_type = "INTERNAL"
  address      = cidrhost(module.landing-untrusted-vpc.subnet_ips["${each.value.region}/landing-untrusted-default-${each.value.trigram}"], 101 + index(var.zones, each.value.zone))
  region       = each.value.region
}

resource "google_compute_address" "nva_static_ip_trusted" {
  for_each     = local.nva_locality
  name         = "nva-ip-trusted-${each.value.trigram}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.trigram}"]
  address_type = "INTERNAL"
  address      = cidrhost(module.landing-trusted-vpc.subnet_ips["${each.value.region}/landing-trusted-default-${each.value.trigram}"], 101 + index(var.zones, each.value.zone))
  region       = each.value.region
}

module "nva" {
  for_each       = local.nva_locality
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-${each.value.trigram}-${each.value.zone}"
  zone           = "${each.value.region}-${each.value.zone}"
  instance_type  = "e2-standard-2"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.trigram}"]
      nat        = false
      addresses = {
        external = null
        internal = google_compute_address.nva_static_ip_untrusted["${each.key}"].address
      }
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.trigram}"]
      nat        = false
      addresses = {
        external = null
        internal = google_compute_address.nva_static_ip_trusted["${each.key}"].address
      }
    }
  ]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    size  = 10
    type  = "pd-balanced"
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    user-data = module.nva-bgp-cloud-config[each.key].cloud_config
    startup-script = file("./data/nva-startup-script.sh")
  }
}