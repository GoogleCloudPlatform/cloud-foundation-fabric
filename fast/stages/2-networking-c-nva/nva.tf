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
  nva_locality = {
    europe-west1-b = { region = "europe-west1", trigram = "ew1", zone = "b" },
    europe-west1-c = { region = "europe-west1", trigram = "ew1", zone = "c" },
    europe-west4-b = { region = "europe-west4", trigram = "ew4", zone = "b" },
    europe-west4-c = { region = "europe-west4", trigram = "ew4", zone = "c" },
  }

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

  nva_configs = {
    europe-west1-b = {
      region       = "europe-west1",
      zone         = "b",
      ip_untrusted = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west1/landing-untrusted-default-ew1"], 101)
      ip_trusted   = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west1/landing-trusted-default-ew1"], 101)
    },
    europe-west1-c = {
      region       = "europe-west1",
      zone         = "c",
      ip_untrusted = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west1/landing-untrusted-default-ew1"], 102)
      ip_trusted   = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west1/landing-trusted-default-ew1"], 102)
    },
    europe-west4-b = {
      region       = "europe-west4",
      zone         = "b",
      ip_untrusted = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west4/landing-untrusted-default-ew4"], 101)
      ip_trusted   = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west4/landing-trusted-default-ew4"], 101)
    },
    europe-west4-c = {
      region       = "europe-west4",
      zone         = "c",
      ip_untrusted = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west4/landing-untrusted-default-ew4"], 102)
      ip_trusted   = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west4/landing-trusted-default-ew4"], 102)
    }
  }
}

# NVA configs
module "nva-bgp-cloud-config" {
  for_each             = local.nva_locality
  source               = "../../../modules/cloud-config-container/simple-nva-bgp"
  enable_health_checks = true
  network_interfaces   = local.routing_config
  frr_config           = "./bgp-files/${each.value.trigram}${each.value.zone}"
}

resource "google_compute_address" "nva_static_ip_untrusted" {
  for_each     = local.nva_configs
  name         = "nva-ip-untrusted-${local.region_shortnames[each.value.region]}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"]
  address_type = "INTERNAL"
  address      = each.value.ip_untrusted
  region       = each.value.region
}

resource "google_compute_address" "nva_static_ip_trusted" {
  for_each     = local.nva_configs
  name         = "nva-ip-trusted-${local.region_shortnames[each.value.region]}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"]
  address_type = "INTERNAL"
  address      = each.value.ip_trusted
  region       = each.value.region
}

module "nva" {
  for_each       = local.nva_configs
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-${local.region_shortnames[each.value.region]}-${each.value.zone}"
  zone           = "${each.value.region}-${each.value.zone}"
  instance_type  = "e2-standard-2"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"]
      nat        = false
      addresses = {
        external = null
        internal = google_compute_address.nva_static_ip_untrusted["${each.key}"].address
      }
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"]
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
  }
}