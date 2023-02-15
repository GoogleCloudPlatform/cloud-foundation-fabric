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
  domain_cr_host = format("%s.",
  trimprefix(module.cloud_run_host.service.status[0].url, "https://"))
}

###############################################################################
#                                  Projects                                   #
###############################################################################

# Main or host project, depending on if there are service projects
module "project_host" {
  source          = "../../../modules/project"
  name            = var.prj_host_id
  project_create  = var.prj_host_create != null
  billing_account = try(var.prj_host_create.billing_account_id, null)
  parent          = try(var.prj_host_create.parent, null)
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

###############################################################################
#                                  Cloud Run                                  #
###############################################################################

# Cloud Run service in main project
module "cloud_run_host" {
  source     = "../../../modules/cloud-run"
  project_id = module.project_host.project_id
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

# VPC in main or host project
module "vpc_host" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_host.project_id
  name       = "vpc-host"
  subnets = [
    {
      ip_cidr_range         = var.ip_ranges["host"].subnet
      name                  = "subnet-host"
      region                = var.region
      enable_private_access = true # PGA enabled
    }
  ]
}

# Host VPC Firewall with default config, IAP for SSH enabled
module "firewall_host" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project_host.project_id
  network    = module.vpc_host.name
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

###############################################################################
#                                    PSC                                      #
###############################################################################

# PSC configured in the host
module "psc_addr_host" {
  source     = "../../../modules/net-address"
  project_id = module.project_host.project_id
  psc_addresses = {
    psc-addr-host = {
      address = var.ip_ranges["host"].psc_addr
      network = module.vpc_host.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "psc_endpoint_host" {
  provider              = google-beta
  project               = module.project_host.project_id
  name                  = "pscaddrhost"
  network               = module.vpc_host.self_link
  ip_address            = module.psc_addr_host.psc_addresses["psc-addr-host"].self_link
  target                = "vpc-sc"
  load_balancing_scheme = ""
}

###############################################################################
#                                    VMs                                      #
###############################################################################

module "vm_test_host" {
  source        = "../../../modules/compute-vm"
  count         = 1 - length(module.project_onprem)
  project_id    = module.project_host.project_id
  zone          = "${var.region}-b"
  name          = "vm-test-host"
  instance_type = "e2-micro"
  network_interfaces = [{
    network    = module.vpc_host.self_link
    subnetwork = module.vpc_host.subnet_self_links["${var.region}/subnet-host"]
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

###############################################################################
#                                    DNS                                      #
###############################################################################

module "private_dns_host" {
  source          = "../../../modules/dns"
  count           = 1 - length(module.project_onprem)
  project_id      = module.project_host.project_id
  type            = "private"
  name            = "dns-host"
  client_networks = [module.vpc_host.self_link]
  domain          = local.domain_cr_host
  recordsets = {
    "A " = { records = [module.psc_addr_host.psc_addresses["psc-addr-host"].address] }
  }
}

module "private_dns_onprem" {
  source          = "../../../modules/dns"
  count           = length(module.project_onprem)
  project_id      = module.project_onprem[0].project_id
  type            = "private"
  name            = "dns-onprem"
  client_networks = [module.vpc_onprem[0].self_link]
  domain          = local.domain_cr_host
  recordsets = {
    "A " = { records = [module.psc_addr_host.psc_addresses["psc-addr-host"].address] }
  }
}

###############################################################################
#                                    VPN                                      #
###############################################################################

# VPN between main project and "onprem" environment
module "vpn_host" {
  source       = "../../../modules/net-vpn-ha"
  count        = length(module.project_onprem)
  project_id   = module.project_host.project_id
  region       = var.region
  network      = module.vpc_host.self_link
  name         = "vpn-host-to-onprem"
  peer_gateway = { gcp = module.vpn_onprem[0].self_link }
  router_config = {
    asn = 65001
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        (var.ip_ranges["host"].psc_addr) = "to-psc-endpoint"
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
  name          = "vpn-onprem-to-host"
  peer_gateway  = { gcp = module.vpn_host[0].self_link }
  router_config = { asn = 65002 }
  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = "169.254.0.1"
        asn     = 65001
      }
      bgp_session_range     = "169.254.0.2/30"
      vpn_gateway_interface = 0
      shared_secret         = module.vpn_host[0].random_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 65001
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 1
      shared_secret         = module.vpn_host[0].random_secret
    }
  }
}
