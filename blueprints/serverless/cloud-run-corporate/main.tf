/**
 * Copyright 2024 Google LLC
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
  service_name_cr1 = "cart"
  service_name_cr2 = "checkout"
  tf_id = (
    var.tf_identity == null
    ? null
    : (
      length(regexall("iam.gserviceaccount.com", var.tf_identity)) > 0
      ? "serviceAccount:${var.tf_identity}"
      : "user:${var.tf_identity}"
    )
  )
  vpc_sc_create = (
    (
      length(module.project_prj1) > 0
      &&
      (var.access_policy != null || var.access_policy_create != null)
    )
    ? 1
    : 0
  )
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
    "cloudresourcemanager.googleapis.com",
    "accesscontextmanager.googleapis.com"
  ]
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
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "vpcaccess"
      ],
      "roles/editor" = [
        "cloudservices"
      ]
    }
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "run.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

###############################################################################
#                                  Cloud Run                                  #
###############################################################################

# Cloud Run service in main project
module "cloud_run_hello" {
  source     = "../../../modules/cloud-run"
  project_id = module.project_main.project_id
  name       = "hello"
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = var.ingress_settings
}

# VPC Access connector in the service project.
# The Shared VPC Ingress feature needs a VPC connector. In the future,
# this need will be removed.
resource "google_vpc_access_connector" "connector" {
  count   = var.prj_svc1_id != null ? 1 : 0
  name    = "connector"
  project = module.project_svc1[0].project_id
  region  = var.region
  subnet {
    name       = module.vpc_main.subnets["${var.region}/subnet-vpc-access"].name
    project_id = module.project_main.project_id
  }
}

# Cloud Run service 1 in service project
module "cloud_run_cart" {
  source     = "../../../modules/cloud-run"
  count      = var.prj_svc1_id != null ? 1 : 0
  project_id = module.project_svc1[0].project_id
  name       = local.service_name_cr1 # "cart"
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = var.ingress_settings
  revision_annotations = {
    vpcaccess_connector = google_vpc_access_connector.connector[0].name
  }
}

# Cloud Run service 2 in service project
module "cloud_run_checkout" {
  source     = "../../../modules/cloud-run"
  count      = var.prj_svc1_id != null ? 1 : 0
  project_id = module.project_svc1[0].project_id
  name       = local.service_name_cr2 # "checkout"
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = var.ingress_settings
  revision_annotations = {
    vpcaccess_connector = google_vpc_access_connector.connector[0].name
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
    {
      ip_cidr_range = var.ip_ranges["main"].subnet
      name          = "subnet-main"
      region        = var.region
    },
    {
      ip_cidr_range = var.ip_ranges["main"].subnet_vpc_access
      name          = "subnet-vpc-access"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.ip_ranges["main"].subnet_proxy
      name          = "subnet-proxy"
      region        = var.region
      active        = true
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
#                                   L7 ILB                                    #
###############################################################################

module "ilb-l7" {
  source     = "../../../modules/net-lb-app-int"
  count      = var.custom_domain == null ? 0 : 1
  project_id = module.project_main.project_id
  name       = "ilb-l7-cr"
  region     = var.region
  backend_service_configs = {
    default = {
      project_id = module.project_svc1[0].project_id
      backends = [{
        group = "cr1"
      }]
      health_checks = []
    }
    cart = {
      project_id = module.project_svc1[0].project_id
      backends = [{
        group = "cr1"
      }]
      health_checks = []
    }
    checkout = {
      project_id = module.project_svc1[0].project_id
      backends = [{
        group = "cr2"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    cr1 = {
      project_id = module.project_svc1[0].project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = local.service_name_cr1
        }
      }
    }
    cr2 = {
      project_id = module.project_svc1[0].project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = local.service_name_cr2
        }
      }
    }
  }
  urlmap_config = {
    default_service = "default"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "pathmap"
    }]
    path_matchers = {
      pathmap = {
        default_service = "default"
        path_rules = [
          {
            paths   = ["/cart", "/cart/*"]
            service = local.service_name_cr1
          },
          {
            paths   = ["/checkout", "/checkout/*"]
            service = local.service_name_cr2
          }
        ]
      }
    }
  }
  vpc_config = {
    network    = module.vpc_main.self_link
    subnetwork = module.vpc_main.subnet_self_links["${var.region}/subnet-main"]
  }
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

module "vm_test_svc1" {
  source        = "../../../modules/compute-vm"
  count         = length(module.project_svc1)
  project_id    = module.project_svc1[0].project_id
  zone          = "${var.region}-b"
  name          = "vm-test-svc1"
  instance_type = "e2-micro"
  network_interfaces = [{
    network    = module.vpc_main.self_link
    subnetwork = module.vpc_main.subnet_self_links["${var.region}/subnet-main"]
  }]
  tags = ["ssh"]
}

###############################################################################
#                                    DNS                                      #
###############################################################################

module "private_dns_main" {
  source     = "../../../modules/dns"
  project_id = module.project_main.project_id
  name       = "dns-main"
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
  count      = var.custom_domain == null ? 0 : 1
  project_id = module.project_main.project_id
  name       = "dns-main-custom"
  zone_config = {
    domain = format("%s.", var.custom_domain)
    private = {
      client_networks = [module.vpc_main.self_link]
    }
  }
  recordsets = {
    "A " = { records = [module.ilb-l7[0].address] }
  }
}

module "private_dns_onprem" {
  source     = "../../../modules/dns"
  count      = length(module.project_onprem)
  project_id = module.project_onprem[0].project_id
  name       = "dns-onprem"
  zone_config = {
    domain = local.cloud_run_domain
    private = {
      client_networks = [module.vpc_onprem[0].self_link]
    }
  }
  recordsets = {
    "A *" = { records = [module.psc_addr_main.psc_addresses["psc-addr"].address] }
  }
}

module "private_dns_prj1" {
  source     = "../../../modules/dns"
  count      = length(module.project_prj1)
  project_id = module.project_prj1[0].project_id
  name       = "dns-prj1"
  zone_config = {
    domain = local.cloud_run_domain
    private = {
      client_networks = [module.vpc_prj1[0].self_link]
    }
  }
  recordsets = {
    "A *" = { records = [module.psc_addr_prj1[0].psc_addresses["psc-addr"].address] }
  }
}

###############################################################################
#                                   VPC SC                                    #
###############################################################################

module "vpc_sc" {
  source               = "../../../modules/vpc-sc"
  count                = local.vpc_sc_create
  access_policy        = var.access_policy_create == null ? var.access_policy : null
  access_policy_create = var.access_policy_create
  ingress_policies = {
    ingress-ids = {
      from = {
        identities    = [local.tf_id]
        access_levels = ["*"]
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["*"]
      }
    }
  }
  service_perimeters_regular = {
    cloudrun = {
      status = {
        resources = [
          "projects/${module.project_main.number}",
          "projects/${module.project_prj1[0].number}"
        ]
        restricted_services = ["run.googleapis.com"]
        ingress_policies    = ["ingress-ids"]
      }
    }
  }
}

###############################################################################
#                                    VPN                                      #
###############################################################################

# VPN between main project and "onprem" environment
module "vpn_main" {
  source     = "../../../modules/net-vpn-ha"
  count      = length(module.project_onprem)
  project_id = module.project_main.project_id
  region     = var.region
  network    = module.vpc_main.self_link
  name       = "vpn-main-to-onprem"
  peer_gateways = {
    default = { gcp = module.vpn_onprem[0].self_link }
  }
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
  source     = "../../../modules/net-vpn-ha"
  count      = length(module.project_onprem)
  project_id = module.project_onprem[0].project_id
  region     = var.region
  network    = module.vpc_onprem[0].self_link
  name       = "vpn-onprem-to-main"
  peer_gateways = {
    default = { gcp = module.vpn_main[0].self_link }
  }
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
