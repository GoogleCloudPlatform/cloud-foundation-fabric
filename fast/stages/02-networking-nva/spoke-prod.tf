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
  billing_account = var.billing_account.id
  name            = "prod-net-spoke-0"
  parent          = var.folder_ids.networking-prod
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
    "stackdriver.googleapis.com",
  ]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
  metric_scopes = [module.landing-project.project_id]
  iam = {
    "roles/dns.admin" = [local.service_accounts.project-factory-prod]
  }
}

module "prod-spoke-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.prod-spoke-project.project_id
  name                            = "prod-spoke-0"
  mtu                             = 1500
  data_folder                     = "${var.data_dir}/subnets/prod"
  delete_default_routes_on_create = true
  psa_ranges                      = var.psa_ranges.prod
  subnets_l7ilb                   = local.l7ilb_subnets.prod
  # Set explicit routes for googleapis; send everything else to NVAs
  routes = {
    private-googleapis = {
      dest_range    = "199.36.153.8/30"
      priority      = 999
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    restricted-googleapis = {
      dest_range    = "199.36.153.4/30"
      priority      = 999
      tags          = []
      next_hop_type = "gateway"
      next_hop      = "default-internet-gateway"
    }
    nva-ew1-to-ew1 = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = ["ew1"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-trusted-ew1.forwarding_rule_address
    }
    nva-ew4-to-ew4 = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = ["ew4"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-trusted-ew4.forwarding_rule_address
    }
    nva-ew1-to-ew4 = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = ["ew1"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-trusted-ew4.forwarding_rule_address
    }
    nva-ew4-to-ew1 = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = ["ew4"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-trusted-ew1.forwarding_rule_address
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

module "peering-prod" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "prod-peering-0"
  local_network = module.prod-spoke-vpc.self_link
  peer_network  = module.landing-trusted-vpc.self_link
}

# Create delegated grants for stage3 service accounts
resource "google_project_iam_binding" "prod_spoke_project_iam_delegated" {
  project = module.prod-spoke-project.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  members = [
    local.service_accounts.data-platform-prod,
    local.service_accounts.project-factory-prod,
  ]
  condition {
    title       = "prod_stage3_sa_delegated_grants"
    description = "Production host project delegated grants."
    expression = format(
      "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
      join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
    )
  }
}
