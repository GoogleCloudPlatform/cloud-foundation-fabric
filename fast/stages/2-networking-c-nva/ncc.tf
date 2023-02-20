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
  ncc_cr_intf_configs = {for item in flatten([
    for priority, region in var.regions : [
      for int_number in [0,1]: {
        "${local.region_shortnames[region]}${int_number}" = {
          host_number = 201 + int_number
          region = region
          redundant = int_number == 0 ? null : "${local.region_shortnames[region]}0"
        }
      }
    ]
  ]): keys(item)[0] => values(item)[0]}

  ncc_cr_base_intf_configs = ({
    for intf, intf_config in local.ncc_cr_intf_configs :
    intf => intf_config if try(intf_config.redundant, null) == null
  })

  ncc_cr_red_intf_configs = ({
    for intf, intf_config in local.ncc_cr_intf_configs :
    intf => intf_config if try(intf_config.redundant, null) != null
  })
}

resource "google_network_connectivity_hub" "hub" {
  name        = "prod-hub"
  description = "NCC Hub for internal multi-region connectivity."
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_spoke" "spoke_untrusted" {
  for_each    = var.regions
  name        = "prod-spoke-untrusted-${each.value}"
  project     = module.landing-project.project_id
  location    = each.value
  description = "Connectivity to untrusted network - region ${each.value}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_locality :
        key => google_compute_address.nva_static_ip_untrusted["${key}"].address if config.region == each.value
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
  for_each    = var.regions
  name        = "prod-spoke-trusted-${local.region_shortnames[each.value]}"
  project     = module.landing-project.project_id
  location    = each.value
  description = "Connectivity to trusted network - region ${local.region_shortnames[each.value]}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_locality :
        key => google_compute_address.nva_static_ip_trusted["${key}"].address if config.region == each.value
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
  for_each = var.regions
  name     = "prod-untrusted-${local.region_shortnames[each.value]}"
  project  = module.landing-project.project_id
  region   = each.value
  network  = module.landing-untrusted-vpc.self_link
  bgp {
    asn = var.router_configs.landing-untrusted-ncc.asn
  }
}

resource "google_compute_router" "routers_trusted" {
  for_each = var.regions
  name     = "prod-trusted-${local.region_shortnames[each.value]}"
  project  = module.landing-project.project_id
  region   = each.value
  network  = module.landing-trusted-vpc.self_link
  bgp {
    asn = var.router_configs.landing-trusted-ncc.asn
  }
}

resource "google_compute_address" "router_intf_addrs_untrusted" {
  for_each     = local.ncc_cr_intf_configs
  name         = "prod-untrusted-${each.key}"
  project      = module.landing-project.project_id
  region       = each.value.region
  subnetwork   = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"]
  address      = cidrhost(module.landing-untrusted-vpc.subnet_ips["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"], each.value.host_number)
  address_type = "INTERNAL"
}

resource "google_compute_address" "router_intf_addrs_trusted" {
  for_each     = local.ncc_cr_intf_configs
  name         = "prod-trusted-${each.key}"
  project      = module.landing-project.project_id
  region       = each.value.region
  subnetwork   = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"]
  address      = cidrhost(module.landing-trusted-vpc.subnet_ips["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"], each.value.host_number)
  address_type = "INTERNAL"
}

resource "google_compute_router_interface" "router_intfs_untrusted" {
  for_each           = local.ncc_cr_base_intf_configs
  name               = "prod-untrusted-${each.key}"
  project            = module.landing-project.project_id
  region             = each.value.region
  router             = google_compute_router.routers_untrusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  subnetwork         = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"]
  private_ip_address = google_compute_address.router_intf_addrs_untrusted[each.key].address
}

resource "google_compute_router_interface" "router_red_intfs_untrusted" {
  for_each            = local.ncc_cr_red_intf_configs
  name                = "prod-untrusted-${each.key}"
  project             = module.landing-project.project_id
  region              = each.value.region
  router              = google_compute_router.routers_untrusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  subnetwork          = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${local.region_shortnames[each.value.region]}"]
  private_ip_address  = google_compute_address.router_intf_addrs_untrusted[each.key].address
  redundant_interface = google_compute_router_interface.router_intfs_untrusted[each.value.redundant].name
}

resource "google_compute_router_interface" "router_intfs_trusted" {
  for_each           = local.ncc_cr_base_intf_configs
  name               = "prod-trusted-${each.key}"
  project            = module.landing-project.project_id
  region             = each.value.region
  router             = google_compute_router.routers_trusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  subnetwork         = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"]
  private_ip_address = google_compute_address.router_intf_addrs_trusted[each.key].address
}

resource "google_compute_router_interface" "router_red_intfs_trusted" {
  for_each            = local.ncc_cr_red_intf_configs
  name                = "prod-trusted-${each.key}"
  project             = module.landing-project.project_id
  region              = each.value.region
  router              = google_compute_router.routers_trusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  subnetwork          = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${local.region_shortnames[each.value.region]}"]
  private_ip_address  = google_compute_address.router_intf_addrs_trusted[each.key].address
  redundant_interface = google_compute_router_interface.router_intfs_trusted[each.value.redundant].name
}

resource "google_compute_router_peer" "peers_untrusted_to_nvas_zone_1" {
  for_each                  = local.ncc_cr_intf_configs
  interface                 = "prod-untrusted-${each.key}"
  name                      = "prod-untrusted-${each.key}-${var.zones[0]}"
  peer_asn                  = var.nva_asn[[for k,v in var.regions : k if v == each.value.region][0]]
  peer_ip_address           = google_compute_address.nva_static_ip_untrusted["${each.value.region}-${var.zones[0]}"].address
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_untrusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  router_appliance_instance = module.nva["${each.value.region}-b"].self_link
}

resource "google_compute_router_peer" "peers_untrusted_to_nvas_zone_2" {
  for_each                  = local.ncc_cr_intf_configs
  interface                 = "prod-untrusted-${each.key}"
  name                      = "prod-untrusted-${each.key}-${var.zones[1]}"
  peer_asn                  = var.nva_asn[[for k,v in var.regions : k if v == each.value.region][0]]
  peer_ip_address           = google_compute_address.nva_static_ip_untrusted["${each.value.region}-${var.zones[1]}"].address
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_untrusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  router_appliance_instance = module.nva["${each.value.region}-c"].self_link
}

resource "google_compute_router_peer" "peers_trusted_to_nvas_zone_1" {
  for_each                  = local.ncc_cr_intf_configs
  interface                 = "prod-trusted-${each.key}"
  name                      = "prod-trusted-${each.key}-${var.zones[0]}"
  peer_asn                  = var.nva_asn[[for k,v in var.regions : k if v == each.value.region][0]]
  peer_ip_address           = google_compute_address.nva_static_ip_trusted["${each.value.region}-${var.zones[0]}"].address
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_trusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  router_appliance_instance = module.nva["${each.value.region}-b"].self_link
}

resource "google_compute_router_peer" "peers_trusted_to_nvas_zone_c" {
  for_each                  = local.ncc_cr_intf_configs
  interface                 = "prod-trusted-${each.key}"
  name                      = "prod-trusted-${each.key}-${var.zones[1]}"
  peer_asn                  = var.nva_asn[[for k,v in var.regions : k if v == each.value.region][0]]
  peer_ip_address           = google_compute_address.nva_static_ip_trusted["${each.value.region}-${var.zones[1]}"].address
  project                   = module.landing-project.project_id
  region                    = each.value.region
  router                    = google_compute_router.routers_trusted[[for k,v in var.regions : k if v == each.value.region][0]].name
  router_appliance_instance = module.nva["${each.value.region}-c"].self_link
}