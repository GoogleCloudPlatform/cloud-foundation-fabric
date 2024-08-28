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

resource "google_network_security_security_profile" "dev_sec_profile" {
  name     = "${var.prefix}-dev-sp-0"
  type     = "THREAT_PREVENTION"
  parent   = "organizations/${var.organization.id}"
  location = "global"
}

resource "google_network_security_security_profile_group" "dev_sec_profile_group" {
  name                      = "${var.prefix}-dev-spg-0"
  parent                    = "organizations/${var.organization.id}"
  location                  = "global"
  description               = "Dev security profile group."
  threat_prevention_profile = try(google_network_security_security_profile.dev_sec_profile.id, null)
}

resource "google_network_security_firewall_endpoint_association" "dev_fw_ep_association" {
  for_each          = toset(var.ngfw_enterprise_config.endpoint_zones)
  name              = "${var.prefix}-dev-epa-${each.key}"
  parent            = "projects/${try(var.host_project_ids.dev-spoke-0, null)}"
  location          = each.value
  firewall_endpoint = google_network_security_firewall_endpoint.firewall_endpoint[each.key].id
  network           = try(local.vpc_ids.dev-spoke-0, null)
  # If TLS inspection is enabled, link the regional TLS inspection policy
  tls_inspection_policy = (
    var.ngfw_tls_configs.tls_enabled
    ? try(var.ngfw_tls_configs.tls_ip_ids_by_region.dev[substr(each.value, 0, length(each.value) - 2)], null)
    : null
  )
}

module "dev-spoke-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  name      = "${var.prefix}-dev-fw-policy"
  parent_id = try(var.host_project_ids.dev-spoke-0, null)
  region    = "global"
  security_profile_group_ids = {
    dev = "//networksecurity.googleapis.com/${try(google_network_security_security_profile_group.dev_sec_profile_group.id, "")}"
  }
  attachments = {
    dev-spoke = try(var.vpc_self_links.dev-spoke-0, null)
  }
  factories_config = {
    cidr_file_path          = var.factories_config.cidrs
    egress_rules_file_path  = "${var.factories_config.firewall_policy_rules.dev}/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.firewall_policy_rules.dev}/ingress.yaml"
  }
}
