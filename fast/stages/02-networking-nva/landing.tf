/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Landing VPC and related resources.

module "landing-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-landing-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled = true
  }
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.project-factory-prod, null)
    ])
    (local.custom_roles.service_project_network_admin) = compact([
      try(local.service_accounts.project-factory-prod, null)
    ])
  }
}

# Untrusted VPC

module "landing-untrusted-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.landing-project.project_id
  name       = "prod-untrusted-landing-0"
  mtu        = 1500
  dns_policy = {
    inbound = false
    logging = false
  }
  data_folder = "${var.data_dir}/subnets/landing-untrusted"
}

module "landing-untrusted-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.landing-untrusted-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.data_dir}/cidrs.yaml"
    rules_folder  = "${var.data_dir}/firewall-rules/landing-untrusted"
  }
}

# NAT

module "landing-nat-ew1" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.landing-project.project_id
  region         = "europe-west1"
  name           = "ew1"
  router_create  = true
  router_name    = "prod-nat-ew1"
  router_network = module.landing-untrusted-vpc.name
  router_asn     = 4200001024
}

module "landing-nat-ew4" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.landing-project.project_id
  region         = "europe-west4"
  name           = "ew4"
  router_create  = true
  router_name    = "prod-nat-ew4"
  router_network = module.landing-untrusted-vpc.name
  router_asn     = 4200001024
}

# Trusted VPC

module "landing-trusted-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-trusted-landing-0"
  delete_default_routes_on_create = true
  mtu                             = 1500

  # Set explicit routes for googleapis in case the default route is deleted
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
  }

  dns_policy = {
    inbound = true
  }

  data_folder = "${var.data_dir}/subnets/landing-trusted"
}

module "landing-trusted-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.landing-trusted-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.data_dir}/cidrs.yaml"
    rules_folder  = "${var.data_dir}/firewall-rules/landing-trusted"
  }
}
