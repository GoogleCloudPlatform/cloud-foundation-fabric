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
  ncc_cr_intf_untrusted_configs = {
    ew10 = { host_number = 201, region = "europe-west1" }
    ew11 = { host_number = 202, region = "europe-west1", redundant = "ew10" }
    ew40 = { host_number = 201, region = "europe-west4" }
    ew41 = { host_number = 202, region = "europe-west4", redundant = "ew40" }
  }

  ncc_cr_base_intf_untrusted_configs = ({
    for intf, intf_config in local.ncc_cr_intf_untrusted_configs :
    intf => intf_config if try(intf_config.redundant, null) == null
  })

  ncc_cr_red_intf_untrusted_configs = ({
    for intf, intf_config in local.ncc_cr_intf_untrusted_configs :
    intf => intf_config if try(intf_config.redundant, null) != null
  })

  ncc_cr_intf_trusted_configs = {
    ew10 = { host_number = 201, region = "europe-west1" }
    ew11 = { host_number = 202, region = "europe-west1", redundant = "ew10" }
    ew40 = { host_number = 201, region = "europe-west4" }
    ew41 = { host_number = 202, region = "europe-west4", redundant = "ew40" }
  }

  ncc_cr_base_intf_trusted_configs = ({
    for intf, intf_config in local.ncc_cr_intf_trusted_configs :
    intf => intf_config if try(intf_config.redundant, null) == null
  })

  ncc_cr_red_intf_trusted_configs = ({
    for intf, intf_config in local.ncc_cr_intf_trusted_configs :
    intf => intf_config if try(intf_config.redundant, null) != null
  })
}

resource "google_network_connectivity_hub" "hub" {
  name        = "prod-hub"
  description = "NCC Hub for internal multi-region connectivity."
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_spoke" "spoke_untrusted" {
  for_each    = var.region_trigram
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
  for_each    = var.region_trigram
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

resource "google_compute_router" "routers_untrusted" {
  for_each = var.region_trigram
  name     = "prod-untrusted-${each.value}"
  project  = module.landing-project.project_id
  region   = each.key
  network  = module.landing-untrusted-vpc.self_link
  bgp {
    asn = var.router_configs.landing-untrusted-ncc.asn
  }
}

resource "google_compute_router" "routers_trusted" {
  for_each = var.region_trigram
  name     = "prod-trusted-${each.value}"
  project  = module.landing-project.project_id
  region   = each.key
  network  = module.landing-trusted-vpc.self_link
  bgp {
    asn = var.router_configs.landing-trusted-ncc.asn
  }
}

resource "google_compute_address" "router_intf_addrs_untrusted" {
  for_each     = local.ncc_cr_intf_untrusted_configs
  name         = "prod-untrusted-${each.key}"
  project      = module.landing-project.project_id
  region       = each.value.region
  subnetwork   = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${var.region_trigram[each.value.region]}"]
  address      = cidrhost(module.landing-untrusted-vpc.subnet_ips["${each.value.region}/landing-untrusted-default-${var.region_trigram[each.value.region]}"], each.value.host_number)
  address_type = "INTERNAL"
}

resource "google_compute_address" "router_intf_addrs_trusted" {
  for_each     = local.ncc_cr_intf_trusted_configs
  name         = "prod-trusted-${each.key}"
  project      = module.landing-project.project_id
  region       = each.value.region
  subnetwork   = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${var.region_trigram[each.value.region]}"]
  address      = cidrhost(module.landing-trusted-vpc.subnet_ips["${each.value.region}/landing-trusted-default-${var.region_trigram[each.value.region]}"], each.value.host_number)
  address_type = "INTERNAL"
}

resource "google_compute_router_interface" "router_intfs_untrusted" {
  for_each           = local.ncc_cr_base_intf_untrusted_configs
  name               = "prod-untrusted-${each.key}"
  project            = module.landing-project.project_id
  region             = each.value.region
  router             = google_compute_router.routers_untrusted[each.value.region].name
  subnetwork         = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${var.region_trigram[each.value.region]}"]
  private_ip_address = google_compute_address.router_intf_addrs_untrusted[each.key].address
}

resource "google_compute_router_interface" "router_red_intfs_untrusted" {
  for_each            = local.ncc_cr_red_intf_untrusted_configs
  name                = "prod-untrusted-${each.key}"
  project             = module.landing-project.project_id
  region              = each.value.region
  router              = google_compute_router.routers_untrusted[each.value.region].name
  subnetwork          = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${var.region_trigram[each.value.region]}"]
  private_ip_address  = google_compute_address.router_intf_addrs_untrusted[each.key].address
  redundant_interface = google_compute_router_interface.router_intfs_untrusted[each.value.redundant].name
}

resource "google_compute_router_interface" "router_intfs_trusted" {
  for_each           = local.ncc_cr_base_intf_trusted_configs
  name               = "prod-trusted-${each.key}"
  project            = module.landing-project.project_id
  region             = each.value.region
  router             = google_compute_router.routers_trusted[each.value.region].name
  subnetwork         = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${var.region_trigram[each.value.region]}"]
  private_ip_address = google_compute_address.router_intf_addrs_trusted[each.key].address
}

resource "google_compute_router_interface" "router_red_intfs_trusted" {
  for_each            = local.ncc_cr_red_intf_trusted_configs
  name                = "prod-trusted-${each.key}"
  project             = module.landing-project.project_id
  region              = each.value.region
  router              = google_compute_router.routers_trusted[each.value.region].name
  subnetwork          = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${var.region_trigram[each.value.region]}"]
  private_ip_address  = google_compute_address.router_intf_addrs_trusted[each.key].address
  redundant_interface = google_compute_router_interface.router_intfs_trusted[each.value.redundant].name
}

resource "google_compute_router_peer" "peers_untrusted_to_nvas_zone_b" {
  for_each                  = local.ncc_cr_intf_untrusted_configs
  interface                 = "prod-untrusted-${each.key}"
  name                      = "prod-untrusted-${each.key}-b"
  peer_asn                  = 65513
  peer_ip_address           = local.nva_configs["${each.value.region}-b"].ip_untrusted
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_untrusted[each.value.region].name
  router_appliance_instance = module.nva["${each.value.region}-b"].self_link
}

resource "google_compute_router_peer" "peers_untrusted_to_nvas_zone_c" {
  for_each                  = local.ncc_cr_intf_untrusted_configs
  interface                 = "prod-untrusted-${each.key}"
  name                      = "prod-untrusted-${each.key}-c"
  peer_asn                  = 65513
  peer_ip_address           = local.nva_configs["${each.value.region}-c"].ip_untrusted
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_untrusted[each.value.region].name
  router_appliance_instance = module.nva["${each.value.region}-c"].self_link
}

resource "google_compute_router_peer" "peers_trusted_to_nvas_zone_b" {
  for_each                  = local.ncc_cr_intf_trusted_configs
  interface                 = "prod-trusted-${each.key}"
  name                      = "prod-trusted-${each.key}-b"
  peer_asn                  = 65514
  peer_ip_address           = local.nva_configs["${each.value.region}-b"].ip_trusted
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_trusted[each.value.region].name
  router_appliance_instance = module.nva["${each.value.region}-b"].self_link
}

resource "google_compute_router_peer" "peers_trusted_to_nvas_zone_c" {
  for_each                  = local.ncc_cr_intf_trusted_configs
  interface                 = "prod-trusted-${each.key}"
  name                      = "prod-trusted-${each.key}-c"
  peer_asn                  = 65514
  peer_ip_address           = local.nva_configs["${each.value.region}-c"].ip_trusted
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_trusted[each.value.region].name
  router_appliance_instance = module.nva["${each.value.region}-c"].self_link
}
