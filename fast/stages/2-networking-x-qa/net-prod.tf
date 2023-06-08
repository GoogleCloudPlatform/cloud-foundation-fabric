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

# TODO: firewall, delegated grants, subnet factories

module "prod-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prd-net-spk-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled = true
  }
  metric_scopes = [module.hub-project.project_id]
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.gke-prod, null),
      try(local.service_accounts.project-factory-prod, null),
    ])
  }
}

module "prod-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.prod-project.project_id
  name       = "prod-spoke-0"
  mtu        = 1500
  # data_folder = "${var.factories_config.data_dir}/subnets/prod"
  # psa_config  = try(var.psa_ranges.prod, null)
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "prod-peering" {
  source                     = "../../../modules/net-vpc-peering"
  prefix                     = "prod-peering-0"
  local_network              = module.hub-trusted-prod-vpc.self_link
  peer_network               = module.prod-vpc.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = true
}
