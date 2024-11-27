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

# tfdoc:file:description Security components for prod spoke VPC.

moved {
  from = google_network_security_security_profile.prod_sec_profile
  to   = google_network_security_security_profile.prod
}

resource "google_network_security_security_profile" "prod" {
  name     = "${var.prefix}-prod-sp-0"
  type     = "THREAT_PREVENTION"
  parent   = "organizations/${var.organization.id}"
  location = "global"
}

moved {
  from = google_network_security_security_profile_group.prod_sec_profile_group
  to   = google_network_security_security_profile_group.prod
}

resource "google_network_security_security_profile_group" "prod" {
  name        = "${var.prefix}-prod-spg-0"
  parent      = "organizations/${var.organization.id}"
  location    = "global"
  description = "prod security profile group."
  threat_prevention_profile = try(
    google_network_security_security_profile.prod.id, null
  )
}

moved {
  from = google_network_security_firewall_endpoint_association.prod_fw_ep_association
  to   = google_network_security_firewall_endpoint_association.prod
}

resource "google_network_security_firewall_endpoint_association" "prod" {
  for_each = toset(var.ngfw_enterprise_config.endpoint_zones)
  name     = "${var.prefix}-prod-epa-${each.key}"
  parent   = "projects/${try(var.host_project_ids.prod-spoke-0, null)}"
  location = each.value
  firewall_endpoint = (
    google_network_security_firewall_endpoint.firewall_endpoint[each.key].id
  )
  network = try(local.vpc_ids.prod-spoke-0, null)
  # If TLS inspection is enabled, link the regional TLS inspection policy
  tls_inspection_policy = (
    var.ngfw_tls_configs.tls_enabled
    # TODO: make this try less verbose and more readable
    ? try(
      var.ngfw_tls_configs.tls_ip_ids_by_region.prod[substr(each.value, 0, length(each.value) - 2)],
      null
    )
    : null
  )
}

module "prod-spoke-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  name      = "${var.prefix}-prod-fw-policy"
  parent_id = try(var.host_project_ids.prod-spoke-0, null)
  region    = "global"
  security_profile_group_ids = {
    prod = local.security_profile_group_ids.prod
  }
  attachments = {
    prod-spoke = try(var.vpc_self_links.prod-spoke-0, null)
  }
  factories_config = {
    cidr_file_path = var.factories_config.cidrs
    egress_rules_file_path = (
      "${var.factories_config.firewall_policy_rules.prod}/egress.yaml"
    )
    ingress_rules_file_path = (
      "${var.factories_config.firewall_policy_rules.prod}/ingress.yaml"
    )
  }
}
