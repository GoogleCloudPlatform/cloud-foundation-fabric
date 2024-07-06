/**
 * Copyright 2024 Google LLC
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
  services = concat(
    [
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
      var.ngfw_enterprise_config.enabled
      ? ["networksecurity.googleapis.com"]
      : []
    ),
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
      try(local.service_accounts.project-factory, null),
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
        try(local.service_accounts.project-factory, null),
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
  psa_configs = var.psa_ranges.dev
  # set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  delete_default_routes_on_create = true
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      next_hop      = "default-internet-gateway"
      next_hop_type = "gateway"
      priority      = 1000
    }
  }
}

resource "google_network_security_security_profile" "dev_sec_profile" {
  count    = var.ngfw_enterprise_config.enabled ? 1 : 0
  name     = "${var.prefix}-dev-sp-0"
  type     = "THREAT_PREVENTION"
  parent   = "organizations/${var.organization.id}"
  location = "global"
}

resource "google_network_security_security_profile_group" "dev_sec_profile_group" {
  count                     = var.ngfw_enterprise_config.enabled ? 1 : 0
  name                      = "${var.prefix}-dev-spg-0"
  parent                    = "organizations/${var.organization.id}"
  location                  = "global"
  description               = "Dev security profile group."
  threat_prevention_profile = try(google_network_security_security_profile.dev_sec_profile[0].id)
}

resource "google_network_security_firewall_endpoint_association" "dev_fw_ep_association" {
  for_each = (
    var.ngfw_enterprise_config.enabled
    ? toset(local.ngfw_endpoint_locations)
    : toset([])
  )
  name              = "${var.prefix}-dev-endpoint-association-${each.key}"
  parent            = module.dev-spoke-project.project_id
  location          = each.value.zone
  firewall_endpoint = google_network_security_firewall_endpoint.firewall_endpoint[each.key].id
  network           = module.dev-spoke-vpc.self_link
}

module "dev-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  name      = "${var.prefix}-dev-fw-policy"
  parent_id = module.dev-spoke-project.project_id
  security_profile_group_ids = {
    dev = "//networksecurity.googleapis.com/${try(google_network_security_security_profile_group.dev_sec_profile_group[0].id, "")}"
  }
  attachments = {
    dev-spoke = module.dev-spoke-vpc.self_link
  }
  factories_config = {
    cidr_file_path          = "${var.factories_config.data_dir}/cidrs.yaml"
    egress_rules_file_path  = "${var.factories_config.data_dir}/firewall-policy-rules/dev/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.data_dir}/firewall-policy-rules/dev/ingress.yaml"
  }
}

module "dev-spoke-firewall" {
  count      = var.ngfw_enterprise_config.enabled ? 0 : 1
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

module "dev-spoke-cloudnat" {
  source         = "../../../modules/net-cloudnat"
  for_each       = toset(var.enable_cloud_nat ? values(module.dev-spoke-vpc.subnet_regions) : [])
  project_id     = module.dev-spoke-project.project_id
  region         = each.value
  name           = "dev-nat-${local.region_shortnames[each.value]}"
  router_create  = true
  router_network = module.dev-spoke-vpc.name
  logging_filter = "ERRORS_ONLY"
}
