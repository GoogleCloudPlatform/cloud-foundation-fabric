# Copyright 2019 Google LLC
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

###############################################################################
#                          Host and service projects                          #
###############################################################################

module "project-host" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "vpc-host"
  services = concat(var.project_services, [
    "cloudkms.googleapis.com", "dns.googleapis.com"
  ])
  iam_roles = [
    "roles/container.hostServiceAgentUser", "roles/owner"
  ]
  iam_members = {
    "roles/container.hostServiceAgentUser" = [
      "serviceAccount:${module.project-svc-gke.gke_service_account}"
    ]
    "roles/owner" = var.owners_host
  }
}

module "project-svc-gce" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "gce"
  services        = var.project_services
  oslogin         = true
  oslogin_admins  = var.owners_gce
  iam_roles       = ["roles/owner"]
  iam_members     = { "roles/owner" = var.owners_gce }
}

module "project-svc-gke" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "gke"
  services        = var.project_services
  iam_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/owner",
  ]
  iam_members = {
    "roles/owner"                   = var.owners_gke
    "roles/monitoring.metricWriter" = [module.service-account-gke-node.iam_email]
    "roles/owner"                   = [module.service-account-gke-node.iam_email]
  }
}

################################################################################
#                                  Networking                                  #
################################################################################

data "google_netblock_ip_ranges" "health-checkers" {
  range_type = "health-checkers"
}

module "vpc-shared" {
  source          = "../../modules/net-vpc"
  project_id      = module.project-host
  name            = "shared-vpc"
  shared_vpc_host = true
  shared_vpc_service_projects = [
    module.project-svc-gce.project_id,
    module.project-svc-gke.project_id
  ]
  subnets = {
    gce = {
      ip_cidr_range      = var.ip_ranges.gce
      region             = var.region
      secondary_ip_range = {}
    }
    gke = {
      ip_cidr_range = var.ip_ranges.gke
      region        = var.region
      secondary_ip_range = {
        pods     = var.ip_secondary_ranges.gke-pods
        services = var.ip_secondary_ranges.gke-services
      }
    }
  }
  iam_roles = {
    gke = ["roles/compute.networkUser", "roles/compute.securityAdmin"]
    gce = ["roles/compute.networkUser"]
  }
  iam_members = {
    gce = {
      "roles/compute.networkUser" = concat(var.owners_gce, [
        "serviceAccount:${module.project-svc-gce.cloudsvc_service_account}",
      ])
    }
    gke = {
      "roles/compute.networkUser" = concat(var.owners_gke, [
        "serviceAccount:${module.project-svc-gke.cloudsvc_service_account}",
        "serviceAccount:${module.project-svc-gke.gke_service_account}",
      ])
      "roles/compute.securityAdmin" = [
        "serviceAccount:${module.project-svc-gke.gke_service_account}",
      ]
    }
  }
}

module "vpc-shared-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = module.project-host.project_id
  network              = module.vpc-shared.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
  custom_rules = {
    health-checks = {
      description          = "HTTP health checks."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = data.google_netblock_ip_ranges.health-checkers.cidr_blocks_ipv4
      targets              = ["health-checks"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [80] }]
      extra_attributes     = {}
    }
  }
}

module "addresses" {
  source     = "../../modules/net-address"
  project_id = module.project-host.project_id
  external_addresses = {
    nat-1 = module.vpc.subnet_regions["default"],
  }
}

module "nat" {
  source        = "../../modules/net-cloudnat"
  project_id    = module.project-host.project_id
  region        = var.region
  name          = "vpc-shared"
  router_create = true
  addresses = [
    module.addresses.external_addresses.nat-1.self_link
  ]
}

################################################################################
#                                     DNS                                      #
################################################################################

module "host-dns" {
  source                             = "../../modules/dns"
  project_id                         = module.project-host.project_id
  type                               = "private"
  name                               = "example"
  domain                             = "example.com."
  private_visibility_config_networks = [module.vpc-shared.self_link]
  record_names                       = ["localhost"]
  record_data                        = [{ rrdatas = "127.0.0.1", type = "A" }]
}

################################################################################
#                                     VM                                      #
################################################################################

module "vm-bastion" {
  source     = "../../modules/compute-vm"
  project_id = module.project-svc-gce.project_id
  region     = module.vpc-host.subnet_regions.gce
  zone       = "${module.vpc-host.subnet_regions.gce}-b"
  name       = "bastion"
  network_interfaces = [{
    network    = module.vpc-host.self_link,
    subnetwork = module.vpc-host.subnet_self_links.gce,
    nat        = false,
    addresses  = null
  }]
  instance_count = 1
  metadata = {
    startup-script = join("\n", [
      "#! /bin/bash",
      "apt-get update",
      "apt-get install -y bash-completion kubectl dnsutils"
    ])
  }
  service_account_create = true
}

module "service-account-gce-vm-gke" {
  source     = "../../modules/iam-service-accounts"
  project_id = module.project-svc-gce.project_id
  names      = ["gce-vm-gke"]
  iam_project_roles = {
    (module.project-svc-gke.project_id) = ["roles/container.developer"]
  }
}

################################################################################
#                                     GKE                                      #
################################################################################

module "cluster-1" {
  source                    = "../../modules/gke-cluster"
  name                      = "cluster-1"
  project_id                = module.project-svc-gke.project_id
  location                  = "${module.vpc-host.subnet_regions.gke}-b"
  network                   = module.vpc-host.self_link
  subnetwork                = module.vpc-host.subnet_self_links.gke
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32
  labels = {
    environment = "test"
  }
  master_authorized_ranges = {
    internal-vms = var.ip_ranges.gce
  }
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.private_service_ranges.cluster-1
  }
}

module "cluster-1-nodepool-1" {
  source                      = "../../modules/gke-nodepool"
  name                        = "nodepool-1"
  project_id                  = module.project-svc-gke.project_id
  location                    = module.cluster-1.location
  cluster_name                = module.cluster-1.name
  node_config_service_account = module.service-account-gke-node.email
}

module "service-account-gke-node" {
  source     = "../../modules/iam-service-accounts"
  project_id = module.project-svc-gke.project_id
  names      = ["gke-node"]
  iam_project_roles = {
    "${local.project}" = ["roles/container.developer", ]
  }
}
