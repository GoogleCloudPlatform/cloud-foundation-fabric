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
    subnetwork    = var.subnet
    access_config = {}
  }

  metadata {
    user-data = data.template_file.vpn-gw.rendered
  }
}

data "template_file" "vpn-gw" {
  template = file(format("$s/assets/$s-vpn-gw-cloud-init.yaml", path.module, var.gateway_type)

  vars = {
    dns_ip_address       = cidrhost(var.local_ip_cidr_range, 3)
    instance_name        = var.name
    local_ip_cidr_range  = var.local_ip_cidr_range
    peer_ip              = var.peer_ip
    peer_ip_wildcard     = format("%%%s", var.peer_ip)
    remote_ip_cidr_range = var.remote_ip_cidr_range
    shared_secret        = var.shared_secret
    server_config_script = indent(4, file(format("$s/assets/server-config.sh", path.module)))
    vpn_ip_address       = cidrhost(var.local_ip_cidr_range, 2)
    web_ip_address       = cidrhost(var.local_ip_cidr_range, 4)
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
