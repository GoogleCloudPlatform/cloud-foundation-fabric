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
  ncc_cr_intf_configs = {
    int-untrusted-ew11 = {
      address     = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west1/landing-untrusted-default-ew1"], 201)
      area        = "untrusted"
      nva_zone    = "europe-west1-b"
      region      = "europe-west1"
      subnetwork  = module.landing-untrusted-vpc.subnet_self_links["europe-west1/landing-untrusted-default-ew1"]
    }
    int-untrusted-ew12 = {
      address     = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west1/landing-untrusted-default-ew1"], 202)
      area        = "untrusted"
      nva_zone    = "europe-west1-c"
      region      = "europe-west1"
      subnetwork  = module.landing-untrusted-vpc.subnet_self_links["europe-west1/landing-untrusted-default-ew1"]
    }
    int-untrusted-ew41 = {
      address     = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west4/landing-untrusted-default-ew4"], 201)
      area        = "untrusted"
      nva_zone    = "europe-west4-b"
      region      = "europe-west4"
      subnetwork  = module.landing-untrusted-vpc.subnet_self_links["europe-west4/landing-untrusted-default-ew4"]
    }
    int-untrusted-ew42 = {
      address     = cidrhost(module.landing-untrusted-vpc.subnet_ips["europe-west4/landing-untrusted-default-ew4"], 202)
      area        = "untrusted"
      nva_zone    = "europe-west4-c"
      region      = "europe-west4"
      subnetwork  = module.landing-untrusted-vpc.subnet_self_links["europe-west4/landing-untrusted-default-ew4"]
    }
    int-trusted-ew11 = {
      address     = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west1/landing-trusted-default-ew1"], 201)
      area        = "trusted"
      nva_zone    = "europe-west1-b"
      region      = "europe-west1"
      subnetwork  = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
    }
    int-trusted-ew12 = {
      address     = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west1/landing-trusted-default-ew1"], 202)
      area        = "trusted"
      nva_zone    = "europe-west1-c"
      region      = "europe-west1"
      subnetwork  = module.landing-trusted-vpc.subnet_self_links["europe-west1/landing-trusted-default-ew1"]
    }
    int-trusted-ew41 = {
      address     = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west4/landing-trusted-default-ew4"], 201)
      area        = "trusted"
      nva_zone    = "europe-west4-b"
      region      = "europe-west4"
      subnetwork  = module.landing-trusted-vpc.subnet_self_links["europe-west4/landing-trusted-default-ew4"]
    }
    int-trusted-ew42 = {
      address     = cidrhost(module.landing-trusted-vpc.subnet_ips["europe-west4/landing-trusted-default-ew4"], 202)
      area        = "trusted"
      nva_zone    = "europe-west4-c"
      region      = "europe-west4"
      subnetwork  = module.landing-trusted-vpc.subnet_self_links["europe-west4/landing-trusted-default-ew4"]
    }
  }
  ncc_routers = toset([for config in local.ncc_cr_intf_configs : "prod-${config.area}-${config.region}"])
  nva_regions = toset([for config in local.nva_configs : config.region])
}

resource "google_network_connectivity_hub" "hub" {
  name        = "prod-hub"
  description = "NCC Hub for internal multi-region connectivity."
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_spoke" "spoke_untrusted" {
  for_each    = local.nva_regions
  name        = "prod-spoke-untrusted-${each.key}"
  project     = module.landing-project.project_id
  location    = each.key
  description = "Connectivity to untrusted network - region ${each.key}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_configs :
        key => config.ip_untrusted if config.region == each.key
      }
      iterator = nva
      content {
        virtual_machine = module.nva[nva.key].self_link
        ip_address      = nva.value
      }
    }
  }
}

resource "google_network_connectivity_spoke" "spoke_trusted" {
  for_each    = local.nva_regions
  name        = "prod-spoke-trusted-${each.key}"
  project     = module.landing-project.project_id
  location    = each.key
  description = "Connectivity to trusted network - region ${each.key}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_configs :
        key => config.ip_trusted if config.region == each.key
      }
      iterator = nva
      content {
        virtual_machine = module.nva[nva.key].self_link
        ip_address      = nva.value
      }
    }
  }
}

resource "google_compute_address" "router_intf_addrs" {
  for_each = {
    for key, config in local.ncc_cr_intf_configs :
    key => config.area
  }
  name         = each.key
  region       = each.value.region
  subnetwork   = each.value.subnetwork
  address      = each.value.address
  address_type = "INTERNAL"
}

resource "google_compute_router" "router_untrusted" {
  for_each = keys(var.region_trigram)
  name    = "prod-untrusted-${each.value}"
  region  = each.value
  network = module.landing-untrusted-vpc.self_link
  bgp {
    asn = 64512
  }
}

resource "google_compute_router" "router_trusted" {
  for_each = keys(var.region_trigram)
  name    = "prod-trusted-${each.value}"
  region  = each.value
  network = module.landing-trusted-vpc.self
  bgp {
    asn = 64512
  }
}

resource "google_compute_router_interface" "interface_untrusted" {
  for_each           = keys(var.region_trigram)
  name               = "prod-untrusted-${each.value}-"
  region             = google_compute_router.router.region
  router             = google_compute_router.router.name
  subnetwork         = google_compute_subnetwork.subnetwork.self_link
  private_ip_address = google_compute_address.addr_intf_redundant.address
}
