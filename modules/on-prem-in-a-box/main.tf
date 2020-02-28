resource "google_compute_address" "static" {
  name = "on-prem-in-a-box"
  region = substr(var.zone, 0, length(var.zone)-2)
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "on_prem_in_a_box" {
  project      = var.project_id
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [concat(var.network_tags, list("onprem-in-a-box"))]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = var.subnet
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata {
    user-data = data.template_file.vpn-gw.rendered
  }
}

data "template_file" "vpn-gw" {
  template = file(format("$s/assets/$s-vpn-gw-cloud-init.yaml", path.module, var.gateway_type))

  vars = {
    instance_name           = var.name
    local_ip_cidr_range     = var.local_ip_cidr_range
    peer_ip                 = var.peer_ip
    remote_ip_cidr_range    = var.remote_ip_cidr_ranges
    shared_secret           = var.shared_secret
    server_config_script    = indent(4, file(format("$s/assets/server-config.sh", path.module)))
    local_gw_ip             = cidrhost(var.local_ip_cidr_range, 1)
    vpn_ip_address          = cidrhost(var.local_ip_cidr_range, 2)
    dns_ip_address          = cidrhost(var.local_ip_cidr_range, 3)
    web_ip_address          = cidrhost(var.local_ip_cidr_range, 4)
    toolbox_ip_address      = cidrhost(var.local_ip_cidr_range, 5)
    peer_bgp_session_range  = var.peer_bgp_session_range
    local_bgp_session_range = var.local_bgp_session_range
    peer_bgp_ip             = split(var.peer_bgp_session_range, "/")[0]
    local_bgp_ip            = split(var.local_bgp_session_range, "/")[0]
    peer_bgp_asn            = var.peer_bgp_asn
    local_bgp_asn           = var.local_bgp_asn
  }
}

resource "google_compute_firewall" "allow-vpn" {
  name        = "onprem-in-a-box-vpn"
  description = "Allow VPN traffic to the onprem instance"

  network = var.network
  project = var.project_id

  source_ranges = var.remote_ip_cidr_range
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
