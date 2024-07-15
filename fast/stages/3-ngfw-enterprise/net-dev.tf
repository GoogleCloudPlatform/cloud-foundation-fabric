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

# tfdoc:file:description Security components for dev spoke VPC.

module "dev-spoke-project" {
  count           = local.enabled_vpcs.dev-spoke-0 ? 1 : 0
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "dev-net-spoke-0"
  parent          = var.folder_ids.networking-dev
  prefix          = var.prefix
  project_create  = false
  services        = ["networksecurity.googleapis.com"]
}

resource "google_network_security_security_profile" "dev_sec_profile" {
  count    = local.enabled_vpcs.dev-spoke-0 ? 1 : 0
  name     = "${var.prefix}-dev-sp-0"
  type     = "THREAT_PREVENTION"
  parent   = "organizations/${var.organization.id}"
  location = "global"
}

resource "google_network_security_security_profile_group" "dev_sec_profile_group" {
  count                     = local.enabled_vpcs.dev-spoke-0 ? 1 : 0
  name                      = "${var.prefix}-dev-spg-0"
  parent                    = "organizations/${var.organization.id}"
  location                  = "global"
  description               = "Dev security profile group."
  threat_prevention_profile = try(google_network_security_security_profile.dev_sec_profile[0].id, null)
}

resource "google_network_security_firewall_endpoint_association" "dev_fw_ep_association" {
  for_each          = toset(var.ngfw_enterprise_config.endpoint_zones)
  name              = "${var.prefix}-dev-epa-${each.key}"
  parent            = try(module.dev-spoke-project[0].project_id, null)
  location          = each.value.zone
  firewall_endpoint = google_network_security_firewall_endpoint.firewall_endpoint[each.key].id
  network           = try(var.vpc_self_links.dev-spoke-0, null)
}

module "dev-spoke-firewall-policy" {
  count     = local.enabled_vpcs.dev-spoke-0 ? 1 : 0
  source    = "../../../modules/net-firewall-policy"
  name      = "${var.prefix}-dev-fw-policy"
  parent_id = try(module.dev-spoke-project[0].project_id, null)
  security_profile_group_ids = {
    dev = "//networksecurity.googleapis.com/${try(google_network_security_security_profile_group.dev_sec_profile_group[0].id, "")}"
  }
  attachments = {
    dev-spoke = try(var.vpc_self_links.dev-spoke-0, null)
  }
  factories_config = {
    cidr_file_path          = "${var.factories_config.data_dir}/cidrs.yaml"
    egress_rules_file_path  = "${var.factories_config.data_dir}/firewall-policy-rules/dev/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.data_dir}/firewall-policy-rules/dev/ingress.yaml"
  }
}
