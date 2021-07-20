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

###############################################################################
#                                   locals                                    #
###############################################################################
locals {
  prefix = var.prefix != null ? "${var.prefix}-" : ""
}

###############################################################################
#                                  projects                                   #
###############################################################################

module "project-onprem" {
  source          = "../../modules/project"
  billing_account = var.billing_account_id
  name            = var.projects_id.onprem
  parent          = var.root_node
  project_create  = var.create_projects
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
}


module "project-hub" {
  source          = "../../modules/project"
  billing_account = var.billing_account_id
  name            = var.projects_id.function
  parent          = var.root_node
  project_create  = var.create_projects
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

###############################################################################
#                                  VPCs                                       #
###############################################################################

module "vpc-onprem" {
  source     = "../../modules/net-vpc"
  project_id = module.project-onprem.project_id
  name       = "${local.prefix}onprem"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.onprem
      name               = "${local.prefix}onprem"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "firewall-onprem" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = module.project-onprem.project_id
  network              = module.vpc-onprem.name
  admin_ranges_enabled = true
  admin_ranges         = []
  custom_rules         = {}
}

module "vpc-hub" {
  source     = "../../modules/net-vpc"
  project_id = module.project-hub.project_id
  name       = "${local.prefix}hub"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.hub
      name               = "${local.prefix}hub"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

###############################################################################
#                                  VPNs                                       #
###############################################################################

module "vpn-onprem" {
  source     = "../../modules/net-vpn-ha"
  project_id = module.project-onprem.project_id
  region     = var.region
  network    = module.vpc-onprem.self_link
  name       = "${local.prefix}onprem-to-hub"
  router_asn = 65001
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
    }
    mode = "CUSTOM"
  }
  peer_gcp_gateway = module.vpn-hub.self_link
  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = 65002
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.0.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.0.6"
        asn     = 65002
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.0.5/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
    }
  }
}

module "vpn-hub" {
  source           = "../../modules/net-vpn-ha"
  project_id       = module.project-hub.project_id
  region           = var.region
  network          = module.vpc-hub.name
  name             = "${local.prefix}hub-to-onprem"
  router_asn       = 65002
  peer_gcp_gateway = module.vpn-onprem.self_link
  router_advertise_config = {
    groups    = ["ALL_SUBNETS"]
    ip_ranges = {
      (var.psc_endpoint) = "to-psc-endpoint"
    }
    mode      = "CUSTOM"
  }
  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.1"
        asn     = 65001
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.0.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn-onprem.random_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.0.5"
        asn     = 65001
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.0.6/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn-onprem.random_secret
    }
  }
}

###############################################################################
#                                  VMs                                        #
###############################################################################

module "test-vm" {
  source         = "../../modules/compute-vm"
  project_id     = module.project-onprem.project_id
  region         = var.region
  zones          = ["${var.zone}"]
  name           = "${local.prefix}test-vm"
  instance_type  = "e2-micro"
  instance_count = 1
  boot_disk      = { image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2104", type = "pd-standard", size = 10 }
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.vpc-onprem.self_link,
      subnetwork = module.vpc-onprem.subnet_self_links["${var.region}/${local.prefix}onprem"],
      nat        = false,
      addresses  = {
        internal = []
        external = []
      },
      alias_ips  = null
    }
  ]
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    preemptible               = false
  }
  metadata = {}
  service_account        = null
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

###############################################################################
#                              Cloud Function                                 #
###############################################################################

module "function-hello" {
  source           = "../../modules/cloud-function"
  project_id       = module.project-hub.project_id
  name             = "${local.prefix}my-hello-function"
  bucket_name      = var.cloud_function_gcs_bucket
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  bundle_config = {
    source_dir  = "${path.module}/assets"
    output_path = "bundle.zip"
  }
  bucket_config = {
    location = var.region
    lifecycle_delete_age = null
  }
  iam   = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}

###############################################################################
#                                  DNS                                        #
###############################################################################

module "private-dns-onprem" {
  source          = "../../modules/dns"
  project_id      = module.project-onprem.project_id
  type            = "private"
  name            = "${local.prefix}private-cloud-function"
  domain          = "${var.region}-${local.prefix}${var.projects_id.function}.cloudfunctions.net."
  client_networks = [module.vpc-onprem.self_link]
  recordsets = [{
    name = "",
    type = "A",
    ttl = 300,
    records = [var.psc_endpoint]
  }]
}

###############################################################################
#                                  PSCs                                       #
###############################################################################

resource "google_compute_global_address" "psc-address" {
  provider     = google
  project      = module.project-hub.project_id
  name         = "pscaddress"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  address_type = "INTERNAL"
  address      = var.psc_endpoint
  network      = module.vpc-hub.self_link
}

resource "google_compute_global_forwarding_rule" "psc-endpoint" {
  provider              = google-beta
  project               = module.project-hub.project_id
  name                  = "pscendpoint"
  network               = module.vpc-hub.self_link
  ip_address            = google_compute_global_address.psc-address.id
  target                = "vpc-sc"
  load_balancing_scheme = ""
}
