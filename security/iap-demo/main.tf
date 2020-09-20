/**
 * Copyright 2020 Google LLC
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

  project_services = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}


# Project where resources will be created
module "project-iap" {
  source          = "../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  name            = var.project_id
  services        = local.project_services
  iam_roles = [
    "roles/owner"
  ]
  iam_members = {
    "roles/owner" = var.project_owners
  }
}

// # ACM Access Level for corp. managed devices only.
// module "level-device-corp-owned" {
//   source = "../../modules/acm-level-basic"
//   policy = var.policy_name
//   project_id = module.project-iap.project_id
//   title  = var.name

//   device_policies = {
//     "require_corp_owned" = true
//   }
// }

# Cloud IAP Brand & Client
module "iap-brand" {
  source        = "../../modules/iap-brand"
  project_id    = module.project-iap.project_id
  support_email = var.support_email
}

# Google-managed Certificate
module "cert" {
  source     = "../../modules/google-cert"
  domains    = var.cert_domains
  name       = var.cert_name
  project_id = module.project-iap.project_id
}

# VPC Network
module "vpc" {
  source = "../../modules/net-vpc"

  name       = var.name
  project_id = module.project-iap.project_id

  subnets = [
    {
      ip_cidr_range = var.range_nodes
      name          = var.name
      region        = var.region
      secondary_ip_range = {
        pods     = var.range_pods
        services = var.range_services
      }
    },
  ]
}

# VPN to on-prem
module "vpn_ha" {
  source = "../../modules/net-vpn-ha"

  network    = module.vpc.self_link
  name       = "${var.name}-to-onprem"
  project_id = module.project-iap.project_id
  region     = var.region
  router_asn = var.asn_local

  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [{
      id         = 0
      ip_address = var.peer_vpn_ip

    }]
  }
  router_advertise_config = {
    groups    = ["ALL_SUBNETS"]
    ip_ranges = { "35.199.192.0/19" = "dns-outbound" }
    mode      = "CUSTOM"
  }

  tunnels = {
    tunnel-0 = {
      bgp_peer = {
        address = cidrhost(var.tunnel_0_link_range, 1)
        asn     = var.asn_peer
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(var.tunnel_0_link_range, 2)}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      shared_secret                   = var.shared_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = cidrhost(var.tunnel_1_link_range, 1)
        asn     = var.asn_peer
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(var.tunnel_1_link_range, 2)}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 0
      shared_secret                   = var.shared_secret
    }
  }
}

# Cloud NAT (to download Ambassador image)
module "nat" {
  source = "../../modules/net-cloudnat"

  name           = var.name
  project_id     = module.project-iap.project_id
  region         = var.region
  router_create  = false
  router_name    = module.vpn_ha.router_name
  router_network = module.vpc.name
}

# Cloud DNS forwarding to on-prem
module "dns" {
  source = "../../modules/dns"

  client_networks = [module.vpc.self_link]
  domain          = var.dns_zone
  forwarders      = var.dns_resolvers
  name            = var.name
  project_id      = module.project-iap.project_id
  type            = "forwarding"
}

# Service account for the GKE nodes
module "gke-sa" {
  source     = "../../modules/iam-service-accounts"
  project_id = module.project-iap.project_id
  names      = ["gke-node"]
  iam_project_roles = {
    (module.project-iap.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

# GKE cluster
module "gke-cluster" {
  source                    = "../../modules/gke-cluster"
  name                      = var.name
  project_id                = module.project-iap.project_id
  location                  = var.region
  network                   = module.vpc.self_link
  subnetwork                = module.vpc.subnet_self_links["${var.region}/${var.name}"]
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32

  master_authorized_ranges = {
    "allowed" = var.master_authorized_ranges
  }

  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.range_master
  }
}

# GKE nodepool
module "gke-nodepool" {
  source                      = "../../modules/gke-nodepool"
  name                        = var.name
  project_id                  = module.project-iap.project_id
  location                    = module.gke-cluster.location
  cluster_name                = module.gke-cluster.name
  node_config_service_account = module.gke-sa.email
}

# IAP connector
module "connector" {
  source = "../../modules/iap-connector"

  address_name        = module.cert.name
  cert_name           = module.cert.name
  iap_client_id       = module.iap-brand.client_id
  iap_client_secret   = module.iap-brand.client_secret
  mappings            = var.mappings
  name                = var.name
  web_user_principals = var.web_user_principals
  project_id          = module.project-iap.project_id
}
