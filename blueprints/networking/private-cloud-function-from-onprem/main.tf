/**
 * Copyright 2022 Google LLC
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
  psc_name = replace(var.name, "-", "")
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  project_create  = var.project_create == null ? false : true
  billing_account = try(var.project_create.billing_account_id, null)
  parent          = try(var.project_create.parent, null)
  services = [
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
}

###############################################################################
#                                  VPCs                                       #
###############################################################################

module "vpc-onprem" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.name}-onprem"
  subnets = [
    {
      ip_cidr_range         = var.ip_ranges.onprem
      name                  = "${var.name}-onprem"
      region                = var.region
      enable_private_access = false
    }
  ]
}

module "firewall-onprem" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc-onprem.name
}

module "vpc-hub" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.name}-hub"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.hub
      name          = "${var.name}-hub"
      region        = var.region
    }
  ]
}

###############################################################################
#                                  VPNs                                       #
###############################################################################

module "vpn-onprem" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.vpc-onprem.self_link
  name       = "${var.name}-onprem-to-hub"
  router_config = {
    asn = 65001
    custom_advertise = {
      all_subnets = true
      ip_ranges   = {}
    }
  }
  peer_gateway = { gcp = module.vpn-hub.self_link }
  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = 65002
      }
      bgp_session_range     = "169.254.0.1/30"
      vpn_gateway_interface = 0
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.0.6"
        asn     = 65002
      }
      bgp_session_range     = "169.254.0.5/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-hub" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.vpc-hub.name
  name       = "${var.name}-hub-to-onprem"
  router_config = {
    asn = 65002
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.psc_endpoint) = "to-psc-endpoint"
      }
    }
  }
  peer_gateway = { gcp = module.vpn-onprem.self_link }

  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.1"
        asn     = 65001
      }
      bgp_session_range     = "169.254.0.2/30"
      vpn_gateway_interface = 0
      shared_secret         = module.vpn-onprem.random_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.0.5"
        asn     = 65001
      }
      bgp_session_range     = "169.254.0.6/30"
      vpn_gateway_interface = 1
      shared_secret         = module.vpn-onprem.random_secret
    }
  }
}

###############################################################################
#                                  VMs                                        #
###############################################################################

module "test-vm" {
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = "${var.region}-b"
  name          = "${var.name}-test"
  instance_type = "e2-micro"
  boot_disk = {
    image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2104"
  }
  network_interfaces = [{
    network    = module.vpc-onprem.self_link
    subnetwork = module.vpc-onprem.subnet_self_links["${var.region}/${var.name}-onprem"]
  }]
  tags = ["ssh"]
}

###############################################################################
#                              Cloud Function                                 #
###############################################################################

module "function-hello" {
  source           = "../../../modules/cloud-function"
  project_id       = module.project.project_id
  name             = var.name
  bucket_name      = "${var.name}-tf-cf-deploy"
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  bundle_config = {
    source_dir  = "${path.module}/assets"
    output_path = "bundle.zip"
  }
  bucket_config = {
    location = var.region
  }
  iam = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}

###############################################################################
#                                  DNS                                        #
###############################################################################

module "private-dns-onprem" {
  source          = "../../../modules/dns"
  project_id      = module.project.project_id
  type            = "private"
  name            = var.name
  domain          = "${var.region}-${module.project.project_id}.cloudfunctions.net."
  client_networks = [module.vpc-onprem.self_link]
  recordsets = {
    "A " = { records = [module.addresses.psc_addresses[local.psc_name].address] }
  }
}

###############################################################################
#                                  PSCs                                       #
###############################################################################

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  psc_addresses = {
    (local.psc_name) = {
      address = var.psc_endpoint
      network = module.vpc-hub.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "psc-endpoint" {
  provider              = google-beta
  project               = module.project.project_id
  name                  = local.psc_name
  network               = module.vpc-hub.self_link
  ip_address            = module.addresses.psc_addresses[local.psc_name].self_link
  target                = "vpc-sc"
  load_balancing_scheme = ""
}
