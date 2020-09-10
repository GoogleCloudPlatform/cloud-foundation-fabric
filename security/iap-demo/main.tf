locals {
  # Set these parameters if establishing Cloud VPN HA/dynamic routing
  asn_local           = var.asn_local
  asn_peer            = var.asn_peer
  billing_account_id  = var.billing_account_id
  tunnel_0_link_range = var.tunnel_0_link_range
  tunnel_1_link_range = var.tunnel_1_link_range
  # Set these parameters if establishing Cloud VPN Classic/static routing
  # General parameters
  cert_domains             = var.cert_domains
  cert_name                = var.cert_name
  dns_zone                 = var.dns_zone
  dns_resolvers            = var.dns_resolvers
  mappings                 = var.mappings
  master_authorized_ranges = var.master_authorized_ranges
  name                     = var.name
  peer_vpn_ip              = var.peer_vpn_ip
  policy_name              = var.policy_name
  project_id               = var.project_id
  project_owners           = var.project_owners
  range_master             = var.range_master
  range_nodes              = var.range_nodes
  range_pods               = var.range_pods
  range_services           = var.range_services
  region                   = var.region
  root_node                = var.root_node
  shared_secret            = var.shared_secret
  support_email            = var.support_email
  web_user_principals      = var.web_user_principals

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
  billing_account = local.billing_account_id
  name            = local.project_id
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
//   policy = local.policy_name
//   project_id = module.project-iap.project_id
//   title  = local.name

//   device_policies = {
//     "require_corp_owned" = true
//   }
// }

# Cloud IAP Brand & Client
module "iap-brand" {
  source        = "../../modules/iap-brand"
  project_id    = module.project-iap.project_id
  support_email = local.support_email
}

# Google-managed Certificate
module "cert" {
  source     = "../../modules/google-cert"
  domains    = local.cert_domains
  name       = local.cert_name
  project_id = module.project-iap.project_id
}

# VPC Network
module "vpc" {
  source = "../../modules/net-vpc"

  name       = local.name
  project_id = module.project-iap.project_id

  subnets = [
    {
      ip_cidr_range = local.range_nodes
      name          = local.name
      region        = local.region
      secondary_ip_range = {
        pods     = local.range_pods
        services = local.range_services
      }
    },
  ]
}

# VPN to on-prem
module "vpn_ha" {
  source = "../../modules/net-vpn-ha"

  network    = module.vpc.self_link
  name       = "${local.name}-to-onprem"
  project_id = module.project-iap.project_id
  region     = local.region
  router_asn = local.asn_local

  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [{
      id         = 0
      ip_address = local.peer_vpn_ip

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
        address = cidrhost(local.tunnel_0_link_range, 1)
        asn     = local.asn_peer
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(local.tunnel_0_link_range, 2)}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = 0
      shared_secret                   = local.shared_secret
    }
    tunnel-1 = {
      bgp_peer = {
        address = cidrhost(local.tunnel_1_link_range, 1)
        asn     = local.asn_peer
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(local.tunnel_1_link_range, 2)}/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = 0
      shared_secret                   = local.shared_secret
    }
  }
}

# Cloud NAT (to download Ambassador image)
module "nat" {
  source = "../../modules/net-cloudnat"

  name           = local.name
  project_id     = module.project-iap.project_id
  region         = local.region
  router_create  = false
  router_name    = module.vpn_ha.router_name
  router_network = module.vpc.name
}

# Cloud DNS forwarding to on-prem
module "dns" {
  source = "../../modules/dns"

  client_networks = [module.vpc.self_link]
  domain          = local.dns_zone
  forwarders      = local.dns_resolvers
  name            = local.name
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
  name                      = local.name
  project_id                = module.project-iap.project_id
  location                  = var.region
  network                   = module.vpc.self_link
  subnetwork                = module.vpc.subnet_self_links["${local.region}/${local.name}"]
  secondary_range_pods      = "pods"
  secondary_range_services  = "services"
  default_max_pods_per_node = 32

  master_authorized_ranges = {
    "allowed" = local.master_authorized_ranges
  }

  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.range_master
  }
}

# GKE nodepool
module "gke-nodepool" {
  source                      = "../../modules/gke-nodepool"
  name                        = local.name
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
  mappings            = local.mappings
  name                = local.name
  web_user_principals = local.web_user_principals
  project_id          = module.project-iap.project_id
}
