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

module "dev-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "dev-net-spk-0"
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

module "dev-vpc" {
  source      = "../../../modules/net-vpc"
  project_id  = module.dev-project.project_id
  name        = "dev-spoke-0"
  mtu         = 1500
  data_folder = "${var.factories_config.data_dir}/subnets/dev"
  # psa_config  = try(var.psa_ranges.dev, null)
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      next_hop_type = "ilb"
      next_hop      = module.hub-addresses.internal_addresses["nva-int-ilb-trusted-dev"].address
    }
  }
}

module "dev-peering" {
  source                     = "../../../modules/net-vpc-peering"
  prefix                     = "dev-peering-0"
  local_network              = module.hub-trusted-dev-vpc.self_link
  peer_network               = module.dev-vpc.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = true
}

