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

# tfdoc:file:description Production spoke VPC and related resources.

module "prod-spoke-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account_id
  name            = "prod-net-spoke-0"
  parent          = var.folder_id
  prefix          = var.prefix
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
  metric_scopes = [module.landing-project.project_id]
  iam = {
    "roles/dns.admin" = [var.project_factory_sa.prod]
  }
}

module "prod-spoke-vpc" {
  source        = "../../../modules/net-vpc"
  project_id    = module.prod-spoke-project.project_id
  name          = "prod-spoke-0"
  mtu           = 1500
  data_folder   = "${var.data_dir}/subnets/prod"
  subnets_l7ilb = local.l7ilb_subnets.prod
  # set explicit routes for googleapis in case the default route is deleted
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      priority      = 1000
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
  }
}

module "prod-spoke-firewall" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = module.prod-spoke-project.project_id
  network             = module.prod-spoke-vpc.name
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  data_folder         = "${var.data_dir}/firewall-rules/prod"
  cidr_template_file  = "${var.data_dir}/cidrs.yaml"
}

module "prod-spoke-cloudnat" {
  for_each       = toset(values(module.prod-spoke-vpc.subnet_regions))
  source         = "../../../modules/net-cloudnat"
  project_id     = module.prod-spoke-project.project_id
  region         = each.value
  name           = "prod-nat-${local.region_trigram[each.value]}"
  router_create  = true
  router_network = module.prod-spoke-vpc.name
  router_asn     = 4200001024
  logging_filter = "ERRORS_ONLY"
}

module "prod-spoke-psa-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.prod-spoke-project.project_id
  psa_addresses = { for r, v in var.psa_ranges.prod : r => {
    address       = cidrhost(v, 0)
    network       = module.prod-spoke-vpc.self_link
    prefix_length = split("/", v)[1]
    }
  }
}
