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
  spoke_vms = [
    for ras in var.router_appliances : {
      ip      = ras.ip
      vm      = ras.vm
      vm_name = element(split("/", ras.vm), length(split("/", ras.vm)) - 1)
    }
  ]
}

resource "google_network_connectivity_hub" "hub" {
  count       = var.hub.create ? 1 : 0
  project     = var.project_id
  name        = var.hub.name
  description = var.hub.description
}

resource "google_network_connectivity_spoke" "spoke-ra" {
  project  = var.project_id
  hub      = try(google_network_connectivity_hub.hub[0].name, var.hub.name)
  location = var.region
  name     = var.name
  linked_router_appliance_instances {
    dynamic "instances" {
      for_each = var.router_appliances
      content {
        virtual_machine = instances.value["vm"]
        ip_address      = instances.value["ip"]
      }
    }
    site_to_site_data_transfer = var.data_transfer
  }
}

resource "google_compute_router" "cr" {
  project = var.project_id
  name    = "${var.name}-cr"
  network = var.vpc_config.network_name
  region  = var.region
  bgp {
    advertise_mode = (
      var.router_config.custom_advertise != null ? "CUSTOM" : "DEFAULT"
    )
    advertised_groups = (
      try(var.router_config.custom_advertise.all_subnets, false)
      ? ["ALL_SUBNETS"] : []
    )
    dynamic "advertised_ip_ranges" {
      for_each = try(var.router_config.custom_advertise.ip_ranges, {})
      content {
        description = advertised_ip_ranges.key
        range       = advertised_ip_ranges.value
      }
    }
    asn                = var.router_config.asn
    keepalive_interval = try(var.router_config.keepalive, null)
  }
}

resource "google_compute_router_interface" "intf1" {
  project            = var.project_id
  name               = "intf1"
  router             = google_compute_router.cr.name
  region             = var.region
  subnetwork         = var.vpc_config.subnet_self_link
  private_ip_address = var.router_config.ip_interface1
}

resource "google_compute_router_interface" "intf2" {
  project             = var.project_id
  name                = "intf2"
  router              = google_compute_router.cr.name
  region              = var.region
  subnetwork          = var.vpc_config.subnet_self_link
  private_ip_address  = var.router_config.ip_interface2
  redundant_interface = google_compute_router_interface.intf1.name
}

resource "google_compute_router_peer" "peer1" {
  for_each = {
    for idx, entry in local.spoke_vms : idx => entry
  }
  project                   = var.project_id
  name                      = "peer1-${each.value.vm_name}"
  router                    = google_compute_router.cr.name
  region                    = var.region
  interface                 = google_compute_router_interface.intf1.name
  peer_asn                  = var.router_config.peer_asn
  peer_ip_address           = each.value.ip
  router_appliance_instance = each.value.vm
}

resource "google_compute_router_peer" "peer2" {
  for_each = {
    for idx, entry in local.spoke_vms : idx => entry
  }
  project                   = var.project_id
  name                      = "peer2-${each.value.vm_name}"
  router                    = google_compute_router.cr.name
  region                    = var.region
  interface                 = google_compute_router_interface.intf2.name
  peer_asn                  = var.router_config.peer_asn
  peer_ip_address           = each.value.ip
  router_appliance_instance = each.value.vm
}
