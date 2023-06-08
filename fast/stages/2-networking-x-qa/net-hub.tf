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

module "hub-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prd-net-hub-0"
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

module "hub-management-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "core-mgmt-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "mgmt"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["mgmt"]
  }]
}

module "hub-untrusted-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "core-untrusted-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "untrusted"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["untrusted"]
  }]
}

module "hub-dmz-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "core-dmz-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "dmz"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["dmz"]
  }]
}

module "hub-inside-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "core-inside-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "inside"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["inside"]
  }]
}

module "hub-trusted-prod-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "prd-trusted-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "trusted-prod"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["trusted-prod"]
  }]
}

module "hub-trusted-dev-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.hub-project.project_id
  name       = "dev-trusted-0"
  mtu        = 1500
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [{
    name          = "trusted-dev"
    region        = var.region
    ip_cidr_range = var.ip_ranges.subnets["trusted-dev"]
  }]
}
