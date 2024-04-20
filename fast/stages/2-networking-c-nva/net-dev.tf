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

# tfdoc:file:description Dev spoke VPC and related resources.

module "dev-spoke-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "dev-net-spoke-0"
  parent          = var.folder_ids.networking-dev
  prefix          = var.prefix
  services = concat([
    "container.googleapis.com",
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
      try(local.service_accounts.gke-dev, null),
      try(local.service_accounts.project-factory-dev, null),
      try(local.service_accounts.project-factory-prod, null),
    ])
  }
  # allow specific service accounts to assign a set of roles
  iam_bindings = {
    sa_delegated_grants = {
      role = "roles/resourcemanager.projectIamAdmin"
      members = compact([
        try(local.service_accounts.data-platform-dev, null),
        try(local.service_accounts.project-factory-dev, null),
        try(local.service_accounts.project-factory-prod, null),
        try(local.service_accounts.gke-dev, null),
      ])
      condition = {
        title       = "dev_stage3_sa_delegated_grants"
        description = "Development host project delegated grants."
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'", local.stage3_sas_delegated_grants))
        )
      }
    }
  }
}

module "dev-spoke-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.dev-spoke-project.project_id
  name       = "dev-spoke-0"
  mtu        = 1500
  dns_policy = {
    logging = var.dns.enable_logging
  }
  factories_config = {
    subnets_folder = "${var.factories_config.data_dir}/subnets/dev"
  }
  delete_default_routes_on_create = true
  psa_configs                     = var.psa_ranges.dev
  # Set explicit routes for googleapis; send everything else to NVAs
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  routes = {
    nva-primary-to-primary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = ["primary"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-landing["primary"].forwarding_rule_addresses[""]
    }
    nva-secondary-to-secondary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = ["secondary"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-landing["secondary"].forwarding_rule_addresses[""]
    }
    nva-primary-to-secondary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = ["primary"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-landing["primary"].forwarding_rule_addresses[""]
    }
    nva-secondary-to-primary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = ["secondary"]
      next_hop_type = "ilb"
      next_hop      = module.ilb-nva-landing["secondary"].forwarding_rule_addresses[""]
    }
  }
}

module "dev-spoke-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.dev-spoke-project.project_id
  network    = module.dev-spoke-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/dev"
  }
}

module "peering-dev" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "dev-peering-0"
  local_network = module.dev-spoke-vpc.self_link
  peer_network  = module.landing-vpc.self_link
}
