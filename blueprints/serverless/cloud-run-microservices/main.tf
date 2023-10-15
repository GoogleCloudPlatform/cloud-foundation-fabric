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
  cloud_run_domain = "run.app."
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
    "dns.googleapis.com",
    "vpcaccess.googleapis.com"
    # "cloudresourcemanager.googleapis.com"
  ]
  skip_delete = true
}

# Service Project 1
module "project_svc1" {
  source          = "../../../modules/project"
  count           = var.prj_svc1_id != null ? 1 : 0
  name            = var.prj_svc1_id
  project_create  = var.prj_svc1_create != null
  billing_account = try(var.prj_svc1_create.billing_account_id, null)
  parent          = try(var.prj_svc1_create.parent, null)
  shared_vpc_service_config = {
    host_project = module.project_main.project_id
    # service_identity_iam = {
    #   "roles/compute.networkUser" = [
    #     "vpcaccess"
    #   ],
    #   "roles/editor" = [
    #     "cloudservices"
    #   ]
    # }
  }
  services = [
    "compute.googleapis.com",
    # "dns.googleapis.com",
    "run.googleapis.com",
  ]
  skip_delete = true
}

###############################################################################
#                                  Cloud Run                                  #
###############################################################################

# Cloud Run service acting as client
module "cloud_run_client" {
  source     = "../../../modules/cloud-run"
  project_id = module.project_main.project_id
  name       = "client"
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = "all"
  revision_annotations = {
    vpcaccess_connector = try(google_vpc_access_connector.connector[0].name, null)
  }
}

# Cloud Run service acting as server
module "cloud_run_server" {
  source     = "../../../modules/cloud-run"
  project_id = try(module.project_svc1[0].project_id, module.project_main.project_id)
  name       = "server"
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = "internal"
}

# VPC Access connector
# The use case where both Cloud Run services are in the same project uses
# a VPC access connector to connect from client to server service.
# The use case with Shared VPC and internal ALB uses Direct VPC Egress.
resource "google_vpc_access_connector" "connector" {
  count   = var.prj_svc1_id == null ? 1 : 0
  name    = "connector"
  project = module.project_main.project_id
  region  = var.region
  subnet {
    name       = module.vpc_main.subnets["${var.region}/subnet-vpc-access"].name
    project_id = module.project_main.project_id
  }
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
    { # regular subnet
      ip_cidr_range = var.ip_ranges["main"].subnet
      name          = "subnet-main"
      region        = var.region
    },
    { # subnet for the VPC access connector
      ip_cidr_range = var.ip_ranges["main"].subnet_vpc_access
      name          = "subnet-vpc-access"
      region        = var.region
    },
    { # subnet for use in Direct VPC Egress
      ip_cidr_range = var.ip_ranges["main"].subnet_vpc_direct
      name          = "subnet-vpc-direct"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    { # subnet for internal ALB
      ip_cidr_range = var.ip_ranges["main"].subnet_proxy
      name          = "subnet-proxy"
      region        = var.region
      active        = true
    }
  ]
}

# # Main VPC Firewall with default config, IAP for SSH enabled
# module "firewall_main" {
#   source     = "../../../modules/net-vpc-firewall"
#   project_id = module.project_main.project_id
#   network    = module.vpc_main.name
#   default_rules_config = {
#     http_ranges  = []
#     https_ranges = []
#   }
# }

###############################################################################
#                                    PSC                                      #
###############################################################################

# PSC configured in the main project
module "psc_addr_main" {
  source     = "../../../modules/net-address"
  project_id = module.project_main.project_id
  psc_addresses = {
    psc-addr = {
      address = var.ip_ranges["main"].psc_addr
      network = module.vpc_main.self_link
    }
  }
}

resource "google_compute_global_forwarding_rule" "psc_endpoint_main" {
  provider              = google-beta
  project               = module.project_main.project_id
  name                  = "pscaddr"
  network               = module.vpc_main.self_link
  ip_address            = module.psc_addr_main.psc_addresses["psc-addr"].self_link
  target                = "vpc-sc"
  load_balancing_scheme = ""
}

###############################################################################
#                                internal ALB                                 #
###############################################################################

module "int-alb" {
  source     = "../../../modules/net-lb-app-int"
  count      = var.prj_svc1_id != null ? 1 : 0
  project_id = module.project_main.project_id
  name       = "int-alb-cr"
  region     = var.region
  backend_service_configs = {
    default = {
      project_id = module.project_svc1[0].project_id
      backends = [{
        group = "cr-neg"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    cr-neg = {
      project_id = module.project_svc1[0].project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = "server"
        }
      }
    }
  }
  vpc_config = {
    network    = module.vpc_main.self_link
    subnetwork = module.vpc_main.subnet_self_links["${var.region}/subnet-main"]
  }
}

###############################################################################
#                                    DNS                                      #
###############################################################################

module "private_dns_main" {
  source     = "../../../modules/dns"
  project_id = module.project_main.project_id
  name       = "cloud-run"
  zone_config = {
    domain = local.cloud_run_domain
    private = {
      client_networks = [module.vpc_main.self_link]
    }
  }
  recordsets = {
    "A *" = { records = [module.psc_addr_main.psc_addresses["psc-addr"].address] }
  }
}

module "private_dns_main_custom" {
  source     = "../../../modules/dns"
  count      = var.prj_svc1_id != null ? 1 : 0
  project_id = module.project_main.project_id
  name       = "cloud-run-custom"
  zone_config = {
    domain = format("%s.", var.custom_domain)
    private = {
      client_networks = [module.vpc_main.self_link]
    }
  }
  recordsets = {
    "A " = { records = [module.int-alb[0].address] }
  }
}
