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

# tfdoc:file:description Production spoke VPC and related resources.

module "prod-spoke-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-spoke-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services = concat([
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
    ],
    (
      var.fast_features.gcve
      ? ["vmwareengine.googleapis.com"]
      : []
    )
  )
  shared_vpc_host_config = {
    enabled = true
  }
  metric_scopes = [module.landing-project.project_id]
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.gke-prod, null),
      try(local.service_accounts.project-factory-prod, null),
    ])
  }
  # allow specific service accounts to assign a set of roles
  iam_bindings = {
    sa_delegated_grants = {
      role = "roles/resourcemanager.projectIamAdmin"
      members = compact([
        try(local.service_accounts.data-platform-prod, null),
        try(local.service_accounts.project-factory-prod, null),
        try(local.service_accounts.gke-prod, null),
      ])
      condition = {
        title       = "prod_stage3_sa_delegated_grants"
        description = "Production host project delegated grants."
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
        )
      }
    }
  }
}

module "prod-spoke-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.prod-spoke-project.project_id
  name       = "prod-spoke-0"
  mtu        = 1500
  dns_policy = {
    logging = var.dns.enable_logging
  }
  factories_config = {
    subnets_folder = "${var.factories_config.data_dir}/subnets/prod"
  }
  delete_default_routes_on_create = true
  psa_configs                     = var.psa_ranges.prod
  # Set explicit routes for googleapis; send everything else to NVAs
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "prod-spoke-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.prod-spoke-project.project_id
  network    = module.prod-spoke-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/prod"
  }
}

module "peering-prod" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "prod-peering-0"
  local_network = module.prod-spoke-vpc.self_link
  peer_network  = module.landing-vpc.self_link
}
