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
  spoke_vms = flatten([
    for spoke_key, spoke in var.spokes : [
      for nva in spoke.nvas : {
        ip        = nva.ip
        vm        = nva.vm
        vm_name   = element(split("/", nva.vm), length(split("/", nva.vm)) - 1)
        spoke_key = spoke_key
        spoke     = spoke
      }
    ]
  ])
}

resource "google_network_connectivity_hub" "hub" {
  project     = var.project_id
  name        = var.name
  description = var.description
}

resource "google_network_connectivity_spoke" "spoke" {
  for_each = var.spokes
  project  = var.project_id
  hub      = google_network_connectivity_hub.hub.id
  location = each.value.region
  name     = "${var.name}-spoke-${each.value.region}"
  linked_router_appliance_instances {
    dynamic "instances" {
      for_each = each.value.nvas
      content {
        virtual_machine = instances.value["vm"]
        ip_address      = instances.value["ip"]
      }
    }
    site_to_site_data_transfer = false
  }
}

resource "google_compute_router" "cr" {
  for_each = var.spokes
  project  = var.project_id
  name     = "${var.name}-cr-${each.value.region}"
  network  = each.value.vpc
  region   = each.value.region
  bgp {
    advertise_mode = (
      each.value.router.custom_advertise != null ? "CUSTOM" : "DEFAULT"
    )
    advertised_groups = (
      try(each.value.router.custom_advertise.all_subnets, false)
      ? ["ALL_SUBNETS"] : []
    )
    dynamic "advertised_ip_ranges" {
      for_each = try(each.value.router.custom_advertise.ip_ranges, {})
      content {
        description = advertised_ip_ranges.key
        range       = advertised_ip_ranges.value
      }
    }
    asn                = var.asn
    keepalive_interval = try(each.value.router.keepalive, null)
  }
}

resource "google_compute_router_interface" "intf1" {
  for_each           = var.spokes
  project            = var.project_id
  name               = "intf1"
  router             = google_compute_router.cr[each.key].name
  region             = each.value.region
  subnetwork         = each.value.subnetwork
  private_ip_address = each.value.router.ip1
}

resource "google_compute_router_interface" "intf2" {
  for_each            = var.spokes
  project             = var.project_id
  name                = "intf2"
  router              = google_compute_router.cr[each.key].name
  region              = each.value.region
  subnetwork          = each.value.subnetwork
  private_ip_address  = each.value.router.ip2
  redundant_interface = google_compute_router_interface.intf1[each.key].name
}

resource "google_compute_router_peer" "peer1" {
  for_each = {
    for entry in local.spoke_vms : entry.ip => entry
  }
  project                   = var.project_id
  name                      = "peer1-${each.value.vm_name}"
  router                    = google_compute_router.cr[each.value.spoke_key].name
  region                    = each.value.spoke.region
  interface                 = google_compute_router_interface.intf1[each.value.spoke_key].name
  peer_asn                  = each.value.spoke.router.peer_asn
  peer_ip_address           = each.key
  router_appliance_instance = each.value.vm
}

resource "google_compute_router_peer" "peer2" {
  for_each = {
    for entry in local.spoke_vms : entry.ip => entry
  }
  project                   = var.project_id
  name                      = "peer2-${each.value.vm_name}"
  router                    = google_compute_router.cr[each.value.spoke_key].name
  region                    = each.value.spoke.region
  interface                 = google_compute_router_interface.intf2[each.value.spoke_key].name
  peer_asn                  = each.value.spoke.router.peer_asn
  peer_ip_address           = each.key
  router_appliance_instance = each.value.vm
}
