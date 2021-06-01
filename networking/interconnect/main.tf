
/**
 * Copyright 2021 Google LLC
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

resource "google_compute_router" "router" {
 
    name    = var.router_name == "" ? "router-${var.vlan_attachment_name}" : var.router_name
    description=var.router_description
    project = var.project_id
    region = var.region
    network = var.network_name
  
  
    bgp  {
         advertise_mode = (
           var.router_advertise_config == null
             ? null
           : var.router_advertise_config.mode
         )
         advertised_groups = (
           var.router_advertise_config == null ? null : (
              var.router_advertise_config.mode != "CUSTOM"
              ? null
              : var.router_advertise_config.groups
             )
        )

      dynamic "advertised_ip_ranges" {
      for_each = (
        var.router_advertise_config == null ? {} : (
          var.router_advertise_config.mode != "CUSTOM"
          ? null
          : var.router_advertise_config.ip_ranges
        )
      )
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }        
      asn= var.asn


    }



}

resource "google_compute_interconnect_attachment" "interconnect_vlan_attachment"{
  name=var.vlan_attachment_name
  description=var.description
  router=google_compute_router.router.id
  interconnect=var.interconnect
  project=var.project_id
  region=var.interconnect_region
  bandwidth=var.bandwidth
  vlan_tag8021q=var.vlan_id
  candidate_subnets=var.candidate_ip_ranges
  provider = google-beta
  admin_enabled=var.admin_enabled
  
}
resource "google_compute_router_interface" "interface" {
  name       = var.interface_name
  project    = var.project_id
  router     = google_compute_router.router.name
  region     = var.region
  ip_range   = var.ip_range
  interconnect_attachment=google_compute_interconnect_attachment.interconnect_vlan_attachment.name
  
}

resource "google_compute_router_peer" "peer" {
  name                      = var.bgp_session_name
  project                   = var.project_id
  router                    = google_compute_router.router.name
  region                    = var.region
  peer_ip_address           = var.peer_ip_address
  peer_asn                  = var.peer_asn
  advertised_route_priority = var.advertised_route_priority
  interface                 = google_compute_interconnect_attachment.interconnect_vlan_attachment.name
  
  
} 