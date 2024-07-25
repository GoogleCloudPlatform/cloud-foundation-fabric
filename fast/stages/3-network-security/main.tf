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

# tfdoc:file:description Next-Generation Firewall Enterprise configuration.

locals {
  enabled_vpcs = {
    dev-spoke-0  = try(var.vpc_self_links.dev-spoke-0, null) != null
    prod-spoke-0 = try(var.vpc_self_links.prod-spoke-0, null) != null
  }
  vpc_ids = {
    for k, v in var.vpc_self_links
    : k => replace(v, "https://www.googleapis.com/compute/v1/", "")
  }
}

# Dedicated quota project for ngfw enterprise endpoints
module "ngfw-quota-project" {
  count           = var.ngfw_enterprise_config.quota_project_id == null ? 1 : 0
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-ngfw-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services        = ["networksecurity.googleapis.com"]
}

module "ext-ngfw-quota-project" {
  count           = var.ngfw_enterprise_config.quota_project_id == null ? 0 : 1
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = var.ngfw_enterprise_config.quota_project_id
  project_create  = false
  services        = ["networksecurity.googleapis.com"]
}

resource "google_network_security_firewall_endpoint" "firewall_endpoint" {
  for_each = toset(var.ngfw_enterprise_config.endpoint_zones)
  name     = "${var.prefix}-ngfw-endpoint-${each.key}"
  parent   = "organizations/${var.organization.id}"
  location = each.value
  billing_project_id = coalesce(
    try(module.ext-ngfw-quota-project[0].id, null),
    try(module.ngfw-quota-project[0].id, null)
  )
}
