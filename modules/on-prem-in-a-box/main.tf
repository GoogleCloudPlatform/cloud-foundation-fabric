/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_address" "static" {
  project      = var.project_id
  name         = var.name
  region       = substr(var.zone, 0, length(var.zone) - 2)
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "on_prem_in_a_box" {
  project      = var.project_id
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = concat(var.network_tags, list("onprem-in-a-box"))

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    user-data = data.template_file.vpn-gw.rendered
  }

}

data "template_file" "vpn-gw" {
  template = file(format("%s/assets/%s-vpn-gw-cloud-init.yaml", path.module, var.vpn_gateway_type))

  vars = {
    instance_name           = var.name
    local_ip_cidr_range     = var.local_ip_cidr_range
    peer_ip                 = var.peer_ip
    remote_ip_cidr_ranges   = var.remote_ip_cidr_ranges
    shared_secret           = var.shared_secret
    local_gw_ip             = cidrhost(var.local_ip_cidr_range, 1)
    vpn_ip_address          = cidrhost(var.local_ip_cidr_range, 2)
    dns_ip_address          = cidrhost(var.local_ip_cidr_range, 3)
    web_ip_address          = cidrhost(var.local_ip_cidr_range, 4)
    toolbox_ip_address      = cidrhost(var.local_ip_cidr_range, 5)
    peer_bgp_session_range  = var.peer_bgp_session_range
    local_bgp_session_range = var.local_bgp_session_range
    peer_bgp_ip             = split("/", var.peer_bgp_session_range)[0]
    local_bgp_ip            = split("/", var.local_bgp_session_range)[0]
    peer_bgp_asn            = var.peer_bgp_asn
    local_bgp_asn           = var.local_bgp_asn
    cloud_dns_zone          = var.cloud_dns_zone
    cloud_dns_forwarder_ip  = var.cloud_dns_forwarder_ip
    on_prem_dns_zone        = var.on_prem_dns_zone
  }
}

resource "google_compute_firewall" "allow-vpn" {
  name        = "onprem-in-a-box-allow-vpn"
  description = "Allow VPN traffic to the onprem instance"

  network = var.network
  project = var.project_id

  source_ranges = [format("%s/32", var.peer_ip)]
  target_tags   = ["onprem-in-a-box"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow-iap" {
  name        = "onprem-in-a-box-allow-iap"
  description = "Allow SSH traffic to the onprem instance from IAP"

  network = var.network
  project = var.project_id

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["onprem-in-a-box"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
