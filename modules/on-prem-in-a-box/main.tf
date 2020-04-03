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

locals {
  corefile = (
    var.coredns_config == null || var.coredns_config == ""
    ? data.template_file.corefile.rendered
    : var.coredns_config
  )
}

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
  tags         = concat(var.network_tags, ["onprem"])

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

  service_account {
    email  = var.service_account.email
    scopes = var.service_account.scopes
  }

}

data "template_file" "corefile" {
  template = file("${path.module}/assets/Corefile")
  vars = {
    dns_domain = var.dns_domain
  }
}

data "template_file" "vpn-gw" {
  template = file(format(
    "%s/assets/%s-vpn-gw-cloud-init.yaml", path.module, var.vpn_config.type
  ))

  vars = {
    coredns_config      = indent(4, local.corefile)
    dns_domain          = var.dns_domain
    instance_name       = var.name
    local_ip_cidr_range = var.local_ip_cidr_range
    local_gw_ip         = cidrhost(var.local_ip_cidr_range, 1)
    vpn_ip_address      = cidrhost(var.local_ip_cidr_range, 2)
    dns_ip_address      = cidrhost(var.local_ip_cidr_range, 3)
    web_ip_address      = cidrhost(var.local_ip_cidr_range, 4)
    toolbox_ip_address  = cidrhost(var.local_ip_cidr_range, 5)
    # vpn config
    peer_ip          = var.vpn_config.peer_ip
    peer_ip_wildcard = "%${var.vpn_config.peer_ip}"
    shared_secret    = var.vpn_config.shared_secret
    # vpn dynamic config
    local_bgp_asn     = var.vpn_dynamic_config.local_bgp_asn
    local_bgp_address = var.vpn_dynamic_config.local_bgp_address
    peer_bgp_asn      = var.vpn_dynamic_config.peer_bgp_asn
    peer_bgp_address  = var.vpn_dynamic_config.peer_bgp_address
    # vpn static ranges
    vpn_static_ranges = join(",", var.vpn_static_ranges)
  }
}

# TODO: use a narrower firewall rule and tie it to the service account

resource "google_compute_firewall" "allow-vpn" {
  name          = "onprem-in-a-box-allow-vpn"
  description   = "Allow VPN traffic to the onprem instance"
  network       = var.network
  project       = var.project_id
  source_ranges = [format("%s/32", var.vpn_config.peer_ip)]
  target_tags   = ["onprem"]
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
  name          = "onprem-in-a-box-allow-iap"
  description   = "Allow SSH traffic to the onprem instance from IAP"
  network       = var.network
  project       = var.project_id
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["onprem"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
