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

# tfdoc:file:description Internal Hub VPC.

module "hub-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "hub"
  mtu        = 1500
  subnets = [
    {
      name          = "hub-nva"
      region        = var.region
      ip_cidr_range = var.ip_ranges.hub-nva
    },
    {
      name          = "hub-a"
      region        = var.region
      ip_cidr_range = var.ip_ranges.hub-a
    },
    {
      name          = "hub-b"
      region        = var.region
      ip_cidr_range = var.ip_ranges.hub-b
    },
  ]
  policy_based_routes = {
    nva-skip = {
      use_default_routing = true
      priority            = 100
      target = {
        tags = ["nva"]
      }
    }
    default-nva = {
      next_hop_ilb_ip = module.hub-lb.forwarding_rule_addresses[""]
      priority        = 101
      filter = {
        src_range  = var.ip_ranges.hub-all
        dest_range = "0.0.0.0/0"
      }
    }
  }
}

module "hub-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.hub-vpc.name
  default_rules_config = {
    admin_ranges = [var.ip_ranges.rfc1918_10]
    ssh_ranges   = ["35.235.240.0/20", "35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  }
}

resource "google_compute_route" "hub-0-0" {
  project      = module.project.project_id
  network      = module.hub-vpc.name
  name         = "hub-0-0"
  description  = "Terraform-managed."
  dest_range   = "0.0.0.0/0"
  priority     = 1000
  next_hop_ilb = module.hub-lb.forwarding_rule_self_links[""]
}

module "hub-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  internal_addresses = {
    hub = {
      region     = var.region
      subnetwork = module.hub-vpc.subnet_self_links["${var.region}/hub-nva"]
      address    = cidrhost(module.hub-vpc.subnet_ips["${var.region}/hub-nva"], -3)
    }
  }
}

module "hub-lb" {
  source     = "../../../modules/net-lb-int"
  project_id = module.project.project_id
  region     = var.region
  name       = "hub-lb"
  vpc_config = {
    network    = module.hub-vpc.name
    subnetwork = module.hub-vpc.subnet_self_links["${var.region}/hub-nva"]
  }
  forwarding_rules_config = {
    "" = {
      global_access = false
      address       = module.hub-addresses.internal_addresses["hub"].address
    }
  }

  backends = [
    {
      failover       = false
      group          = google_compute_instance_group.nva-a.id
      balancing_mode = "CONNECTION"
    },
    {
      failover       = false
      group          = google_compute_instance_group.nva-b.id
      balancing_mode = "CONNECTION"
    },
  ]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}


module "vpn-hub-a" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.hub-vpc.self_link
  name       = "hub-a"
  peer_gateways = {
    default = { gcp = module.vpn-a-hub.self_link }
  }
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        "0.0.0.0/0" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-a-hub.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-a-hub.random_secret
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-hub-b" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.hub-vpc.self_link
  name       = "hub-b"
  peer_gateways = {
    default = { gcp = module.vpn-b-hub.self_link }
  }
  router_config = {
    asn = 64513
    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        "0.0.0.0/0" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.6"
        asn     = 64515
      }
      bgp_session_range     = "169.254.1.5/30"
      shared_secret         = module.vpn-b-hub.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.6"
        asn     = 64515
      }
      bgp_session_range     = "169.254.2.5/30"
      shared_secret         = module.vpn-b-hub.random_secret
      vpn_gateway_interface = 1
    }
  }
}

module "peering-hub-a" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "a"
  local_network = module.hub-vpc.id
  peer_network  = module.spoke-peering-a-vpc.id
}

module "peering-hub-b" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "b"
  local_network = module.hub-vpc.id
  peer_network  = module.spoke-peering-b-vpc.id
  depends_on    = [module.spoke-peering-a-vpc.id]
}

