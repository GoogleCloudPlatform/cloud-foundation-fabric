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
  domain_cr_main = format("%s.",
  trimprefix(module.cloud_run_main.service.status[0].url, "https://"))
}

###############################################################################
#                                  Projects                                   #
###############################################################################

# Main project
module "project_main" {
  source          = "../../../modules/project"
  name            = var.prj_main_id
  project_create  = var.prj_main_create != null
  billing_account = try(var.prj_main_create.billing_account_id, null)
  parent          = try(var.prj_main_create.parent, null)
  # Enable Shared VPC by default, some use cases will use this project as host
  shared_vpc_host_config = {
    enabled = true
  }
  services = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
  skip_delete = true
}

# Simulated onprem environment
module "project_onprem" {
  source          = "../../../modules/project"
  count           = var.prj_onprem_id != null ? 1 : 0
  name            = var.prj_onprem_id
  project_create  = var.prj_onprem_create != null
  billing_account = try(var.prj_onprem_create.billing_account_id, null)
  parent          = try(var.prj_onprem_create.parent, null)
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
  skip_delete = true
}

# Project 1
module "project_prj1" {
  source          = "../../../modules/project"
  count           = var.prj_prj1_id != null ? 1 : 0
  name            = var.prj_prj1_id
  project_create  = var.prj_prj1_create != null
  billing_account = try(var.prj_prj1_create.billing_account_id, null)
  parent          = try(var.prj_prj1_create.parent, null)
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com"
  ]
  skip_delete = true
}

###############################################################################
#                                  Cloud Run                                  #
###############################################################################

# Cloud Run service in main project
module "cloud_run_main" {
  source     = "../../../modules/cloud-run"
  project_id = module.project_main.project_id
  name       = var.run_svc_name
  region     = var.region
  containers = [{
    image         = var.image
    options       = null
    ports         = null
    resources     = null
    volume_mounts = null
  }]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = var.ingress_settings
}

###############################################################################
#                                    VPCs                                     #
###############################################################################

# VPC in main project
module "vpc_main" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_main.project_id
  name       = "vpc-main"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges["main"].subnet
      name          = "subnet-main"
      region        = var.region
    }
  ]
}

# Main VPC Firewall with default config, IAP for SSH enabled
module "firewall_main" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project_main.project_id
  network    = module.vpc_main.name
  default_rules_config = {
    http_ranges  = []
    https_ranges = []
  }
}

# VPC in simulated onprem environment
module "vpc_onprem" {
  source     = "../../../modules/net-vpc"
  count      = length(module.project_onprem)
  project_id = module.project_onprem[0].project_id
  name       = "vpc-onprem"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges["onprem"].subnet
      name          = "subnet-onprem"
      region        = var.region
    }
  ]
}

# Onprem VPC Firewall with default config, IAP for SSH enabled
module "firewall_onprem" {
  source     = "../../../modules/net-vpc-firewall"
  count      = length(module.project_onprem)
  project_id = module.project_onprem[0].project_id
  network    = module.vpc_onprem[0].name
  default_rules_config = {
    http_ranges  = []
    https_ranges = []
  }
}

# VPC in project 1
module "vpc_prj1" {
  source     = "../../../modules/net-vpc"
  count      = length(module.project_prj1)
  project_id = module.project_prj1[0].project_id
  name       = "vpc-prj1"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges["prj1"].subnet
      name          = "subnet-prj1"
      region        = var.region
    }
  ]
}

# Project 1 VPC Firewall with default config, IAP for SSH enabled
module "firewall_prj1" {
  source     = "../../../modules/net-vpc-firewall"
  count      = length(module.project_prj1)
  project_id = module.project_prj1[0].project_id
  network    = module.vpc_prj1[0].name
  default_rules_config = {
    http_ranges  = []
    https_ranges = []
  }
}

###############################################################################
#                                    PSC                                      #
###############################################################################

# PSC configured in the main project
module "psc_addr_main" {
  source     = "../../../modules/net-address"
  project_id = module.project_main.project_id
  psc_addresses = {
    psc-addr-main = {
      address = var.ip_ranges["main"].psc_addr
      network = module.vpc_main.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "psc_endpoint_main" {
  provider              = google-beta
  project               = module.project_main.project_id
  name                  = "pscaddrmain"
  network               = module.vpc_main.self_link
  ip_address            = module.psc_addr_main.psc_addresses["psc-addr-main"].self_link
  target                = "vpc-sc"
  load_balancing_scheme = ""
}

# PSC configured in project 1
module "psc_addr_prj1" {
  source     = "../../../modules/net-address"
  count      = length(module.project_prj1)
  project_id = module.project_prj1[0].project_id
  psc_addresses = {
    psc-addr = {
      address = var.ip_ranges["prj1"].psc_addr
      network = module.vpc_prj1[0].self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "psc_endpoint_prj1" {
  provider              = google-beta
  count                 = length(module.project_prj1)
  project               = module.project_prj1[0].project_id
  name                  = "pscaddr"
  network               = module.vpc_prj1[0].self_link
  ip_address            = module.psc_addr_prj1[0].psc_addresses["psc-addr"].self_link
  target                = "vpc-sc"
  load_balancing_scheme = ""
}

###############################################################################
#                                    VMs                                      #
###############################################################################

module "vm_test_main" {
  source        = "../../../modules/compute-vm"
  project_id    = module.project_main.project_id
  zone          = "${var.region}-b"
  name          = "vm-test-main"
  instance_type = "e2-micro"
  network_interfaces = [{
    network    = module.vpc_main.self_link
    subnetwork = module.vpc_main.subnet_self_links["${var.region}/subnet-main"]
  }]
  tags = ["ssh"]
}

module "vm_test_onprem" {
  source        = "../../../modules/compute-vm"
  count         = length(module.project_onprem)
  project_id    = module.project_onprem[0].project_id
  zone          = "${var.region}-b"
  name          = "vm-test-onprem"
  instance_type = "e2-micro"
  network_interfaces = [{
    network    = module.vpc_onprem[0].self_link
    subnetwork = module.vpc_onprem[0].subnet_self_links["${var.region}/subnet-onprem"]
  }]
  tags = ["ssh"]
}

module "vm_test_prj1" {
  source        = "../../../modules/compute-vm"
  count         = length(module.project_prj1)
  project_id    = module.project_prj1[0].project_id
  zone          = "${var.region}-b"
  name          = "vm-test-prj1"
  instance_type = "e2-micro"
  network_interfaces = [{
    network    = module.vpc_prj1[0].self_link
    subnetwork = module.vpc_prj1[0].subnet_self_links["${var.region}/subnet-prj1"]
  }]
  tags = ["ssh"]
}

###############################################################################
#                                    DNS                                      #
###############################################################################

module "private_dns_main" {
  source          = "../../../modules/dns"
  project_id      = module.project_main.project_id
  type            = "private"
  name            = "dns-main"
  client_networks = [module.vpc_main.self_link]
  domain          = local.domain_cr_main
  recordsets = {
    "A " = { records = [module.psc_addr_main.psc_addresses["psc-addr-main"].address] }
  }
}

module "private_dns_onprem" {
  source          = "../../../modules/dns"
  count           = length(module.project_onprem)
  project_id      = module.project_onprem[0].project_id
  type            = "private"
  name            = "dns-onprem"
  client_networks = [module.vpc_onprem[0].self_link]
  domain          = local.domain_cr_main
  recordsets = {
    "A " = { records = [module.psc_addr_main.psc_addresses["psc-addr-main"].address] }
  }
}

module "private_dns_prj1" {
  source          = "../../../modules/dns"
  count           = length(module.project_prj1)
  project_id      = module.project_prj1[0].project_id
  type            = "private"
  name            = "dns-prj1"
  client_networks = [module.vpc_prj1[0].self_link]
  domain          = local.domain_cr_main
  recordsets = {
    "A " = { records = [module.psc_addr_prj1[0].psc_addresses["psc-addr"].address] }
  }
}

###############################################################################
#                                    VPN                                      #
###############################################################################

# VPN between main project and "onprem" environment
module "vpn_main" {
  source       = "../../../modules/net-vpn-ha"
  count        = length(module.project_onprem)
  project_id   = module.project_main.project_id
  region       = var.region
  network      = module.vpc_main.self_link
  name         = "vpn-main-to-onprem"
  peer_gateway = { gcp = module.vpn_onprem[0].self_link }
  router_config = {
    asn = 65001
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.ip_ranges["main"].psc_addr) = "to-psc-endpoint"
      }
    }
  }
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
        address = "169.254.1.2"
        asn     = 65002
      }
      bgp_session_range     = "169.254.1.1/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn_onprem" {
  source        = "../../../modules/net-vpn-ha"
  count         = length(module.project_onprem)
  project_id    = module.project_onprem[0].project_id
  region        = var.region
  network       = module.vpc_onprem[0].self_link
  name          = "vpn-onprem-to-main"
  peer_gateway  = { gcp = module.vpn_main[0].self_link }
  router_config = { asn = 65002 }
  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.1"
        asn     = 65001
      }
      bgp_session_range     = "169.254.0.2/30"
      vpn_gateway_interface = 0
      shared_secret         = module.vpn_main[0].random_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 65001
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 1
      shared_secret         = module.vpn_main[0].random_secret
    }
  }
}
