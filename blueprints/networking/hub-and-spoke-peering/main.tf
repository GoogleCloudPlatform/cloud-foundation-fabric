# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  vm-instances = [
    module.vm-hub.instance,
    module.vm-spoke-1.instance,
    module.vm-spoke-2.instance
  ]
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion dnsutils kubectl"
  ])
}

###############################################################################
#                                   project                                   #
###############################################################################

module "project" {
  source          = "../../../modules/project"
  project_create  = var.project_create != null
  billing_account = try(var.project_create.billing_account, null)
  compute_metadata = var.project_create.oslogin != true ? {} : {
    enable-oslogin = "true"
  }
  parent = try(var.project_create.parent, null)
  name   = var.project_id
  services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}

################################################################################
#                                Hub networking                                #
################################################################################

module "vpc-hub" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-hub"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.hub
      name          = "${var.prefix}-hub-1"
      region        = var.region
    }
  ]
}

module "nat-hub" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-hub"
  router_name    = "${var.prefix}-hub"
  router_network = module.vpc-hub.self_link
}

module "vpc-hub-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = var.project_id
  network    = module.vpc-hub.name
  default_rules_config = {
    admin_ranges = values(var.ip_ranges)
  }
}

################################################################################
#                              Spoke 1 networking                              #
################################################################################

module "vpc-spoke-1" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-spoke-1"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.spoke-1
      name          = "${var.prefix}-spoke-1-1"
      region        = var.region
    }
  ]
}

module "vpc-spoke-1-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc-spoke-1.name
  default_rules_config = {
    admin_ranges = values(var.ip_ranges)
  }
}

module "nat-spoke-1" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-spoke-1"
  router_name    = "${var.prefix}-spoke-1"
  router_network = module.vpc-spoke-1.self_link
}

module "hub-to-spoke-1-peering" {
  source        = "../../../modules/net-vpc-peering"
  local_network = module.vpc-hub.self_link
  peer_network  = module.vpc-spoke-1.self_link
  routes_config = {
    local = { export = true, import = false }
    peer  = { export = false, import = true }
  }
}

################################################################################
#                              Spoke 2 networking                              #
################################################################################

module "vpc-spoke-2" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-spoke-2"
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.spoke-2
      name          = "${var.prefix}-spoke-2-1"
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.ip_secondary_ranges.spoke-2-pods
        services = var.ip_secondary_ranges.spoke-2-services
      }
    }
  ]
}

module "vpc-spoke-2-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc-spoke-2.name
  default_rules_config = {
    admin_ranges = values(var.ip_ranges)
  }
}

module "nat-spoke-2" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-spoke-2"
  router_name    = "${var.prefix}-spoke-2"
  router_network = module.vpc-spoke-2.self_link
}

module "hub-to-spoke-2-peering" {
  source        = "../../../modules/net-vpc-peering"
  local_network = module.vpc-hub.self_link
  peer_network  = module.vpc-spoke-2.self_link
  routes_config = {
    local = { export = true, import = false }
    peer  = { export = false, import = true }
  }
  depends_on = [module.hub-to-spoke-1-peering]
}

################################################################################
#                                   Test VMs                                   #
################################################################################

module "vm-hub" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "${var.prefix}-hub"
  network_interfaces = [{
    network    = module.vpc-hub.self_link
    subnetwork = module.vpc-hub.subnet_self_links["${var.region}/${var.prefix}-hub-1"]
    nat        = false
    addresses  = null
  }]
  metadata = { startup-script = local.vm-startup-script }
  service_account = {
    email = module.service-account-gce.email
  }
  tags = ["ssh"]
}

module "vm-spoke-1" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "${var.prefix}-spoke-1"
  network_interfaces = [{
    network    = module.vpc-spoke-1.self_link
    subnetwork = module.vpc-spoke-1.subnet_self_links["${var.region}/${var.prefix}-spoke-1-1"]
    nat        = false
    addresses  = null
  }]
  metadata = { startup-script = local.vm-startup-script }
  service_account = {
    email = module.service-account-gce.email
  }
  tags = ["ssh"]
}

module "vm-spoke-2" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "${var.prefix}-spoke-2"
  network_interfaces = [{
    network    = module.vpc-spoke-2.self_link
    subnetwork = module.vpc-spoke-2.subnet_self_links["${var.region}/${var.prefix}-spoke-2-1"]
    nat        = false
    addresses  = null
  }]
  metadata = { startup-script = local.vm-startup-script }
  service_account = {
    email = module.service-account-gce.email
  }
  tags = ["ssh"]
}


module "service-account-gce" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-gce-test"
  iam_project_roles = {
    (var.project_id) = [
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

################################################################################
#                                     GKE                                      #
################################################################################

module "cluster-1" {
  source     = "../../../modules/gke-cluster-standard"
  name       = "${var.prefix}-cluster-1"
  project_id = module.project.project_id
  location   = "${var.region}-b"
  vpc_config = {
    network    = module.vpc-spoke-2.self_link
    subnetwork = module.vpc-spoke-2.subnet_self_links["${var.region}/${var.prefix}-spoke-2-1"]
    master_authorized_ranges = {
      for name, range in var.ip_ranges : name => range
    }
    master_ipv4_cidr_block = var.private_service_ranges.spoke-2-cluster-1
  }
  max_pods_per_node = 32
  labels = {
    environment = "test"
  }
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = true
    peering_config = {
      export_routes = true
      import_routes = false
    }
  }
}

module "cluster-1-nodepool-1" {
  source       = "../../../modules/gke-nodepool"
  name         = "${var.prefix}-nodepool-1"
  project_id   = module.project.project_id
  location     = module.cluster-1.location
  cluster_name = module.cluster-1.name
  service_account = {
    email = module.service-account-gke-node.email
  }
}

# roles assigned via this module use non-authoritative IAM bindings at the
# project level, with no risk of conflicts with pre-existing roles

module "service-account-gke-node" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-gke-node"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter", "roles/monitoring.metricWriter",
    ]
  }
}

################################################################################
#                               GKE peering VPN                                #
################################################################################

module "vpn-hub" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.vpc-hub.name
  name       = "${var.prefix}-hub"
  peer_gateways = {
    default = { gcp = module.vpn-spoke-2.self_link }
  }
  router_config = {
    asn = 64516
    custom_advertise = {
      all_subnets          = true
      all_vpc_subnets      = true
      all_peer_vpc_subnets = true
      ip_ranges = {
        "10.0.0.0/8" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64515
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64515
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}


module "vpn-spoke-2" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.project.project_id
  region     = var.region
  network    = module.vpc-spoke-2.name
  name       = "${var.prefix}-spoke-2"
  router_config = {
    asn = 64515
    custom_advertise = {
      all_subnets          = true
      all_vpc_subnets      = true
      all_peer_vpc_subnets = true
      ip_ranges = {
        "10.0.0.0/8"                                      = "default"
        "${var.private_service_ranges.spoke-2-cluster-1}" = "access to control plane"
      }
    }
  }
  peer_gateways = {
    default = { gcp = module.vpn-hub.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64516
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-hub.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64516
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-hub.random_secret
      vpn_gateway_interface = 1
    }
  }
}
