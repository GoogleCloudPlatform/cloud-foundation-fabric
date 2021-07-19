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
#                                  projects                                   #
###############################################################################

module "project-onprem" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v5.0.0"
  billing_account = var.billing_account_id
  name            = var.onprem_project_id
  parent          = var.root_id
  project_create  = var.create_projects
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
}


module "project-gcp" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v5.0.0"
  billing_account = var.billing_account_id
  name            = var.gcp_project_id
  parent          = var.root_id
  project_create  = var.create_projects
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
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v5.0.0"
  project_id = module.project-onprem.project_id
  name       = "onprem-net"
  subnets = [
    {
      ip_cidr_range      = var.onprem_ip_range
      name               = "onprem-sub"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "firewall-onprem" {
  source               = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v5.0.0"
  project_id           = module.project-onprem.project_id
  network              = module.vpc-onprem.name
  admin_ranges_enabled = true
  admin_ranges         = ["0.0.0.0/0"]
  custom_rules         = {}
}

module "vpc-gcp" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v5.0.0"
  project_id = module.project-gcp.project_id
  name       = "gcp-net"
  subnets = [
    {
      ip_cidr_range      = var.gcp_ip_range
      name               = "gcp-sub"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "firewall-gcp" {
  source               = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v5.0.0"
  project_id           = module.project-gcp.project_id
  network              = module.vpc-gcp.name
  admin_ranges_enabled = true
  admin_ranges         = ["0.0.0.0/0"]
  custom_rules         = {}
}

###############################################################################
#                                  VPNs                                       #
###############################################################################

module "vpn-onprem" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v5.0.0"
  project_id = module.project-onprem.project_id
  region     = var.region
  network    = module.vpc-onprem.self_link
  name       = "onprem-to-gcp"
  router_asn = 65001
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
    }
    mode = "CUSTOM"
  }
  peer_gcp_gateway = module.vpn-gcp.self_link
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

module "vpn-gcp" {
  source           = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v5.0.0"
  project_id       = module.project-gcp.project_id
  region           = var.region
  network          = module.vpc-gcp.name
  name             = "gcp-to-onprem"
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
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm?ref=v5.0.0"
  project_id     = module.project-onprem.project_id
  region         = var.region
  zones          = ["${var.zone}"]
  name           = "test-vm"
  instance_type  = "e2-micro"
  instance_count = 1
  boot_disk      = { image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2104", type = "pd-standard", size = 10 }
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.vpc-onprem.self_link,
      subnetwork = module.vpc-onprem.subnet_self_links["${var.region}/onprem-sub"],
      nat        = false,
      addresses = {
        internal = [cidrhost(var.onprem_ip_range, 2)]
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
  tags                   = []
}

###############################################################################
#                              Cloud Function                                 #
###############################################################################

module "function-hello" {
  source           = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/cloud-function?ref=v5.0.0"
  project_id       = module.project-gcp.project_id
  name             = "my-hello-function"
  bucket_name      = var.cloud_function_gcs_bucket
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  depends_on = [
    module.bucket-functions
  ]
  bundle_config = {
    source_dir  = "function_src"
    output_path = "bundle.zip"
  }
  iam   = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}

###############################################################################
#                                    GCS                                      #
###############################################################################

module "bucket-functions" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gcs?ref=v5.0.0"
  project_id = module.project-gcp.project_id
  name       = var.cloud_function_gcs_bucket
  iam        = {}
}

###############################################################################
#                                  DNS                                        #
###############################################################################

module "private-dns-onprem" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/dns?ref=v5.0.0"
  project_id      = module.project-onprem.project_id
  type            = "private"
  name            = "private-cloud-function"
  domain          = "${var.region}-${var.gcp_project_id}.cloudfunctions.net."
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
  project      = module.project-gcp.project_id
  name         = "pscaddress"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  address_type = "INTERNAL"
  address      = var.psc_endpoint
  network      = module.vpc-gcp.self_link
}

resource "google_compute_global_forwarding_rule" "psc-endpoint" {
  provider              = google-beta
  project               = module.project-gcp.project_id
  name                  = "pscendpoint"
  network               = module.vpc-gcp.self_link
  ip_address            = google_compute_global_address.psc-address.id
  target                = "vpc-sc"
  load_balancing_scheme = ""
}
