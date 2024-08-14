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
  create_quota_project = (
    var.ngfw_enterprise_config.quota_project_id == null
    ? true
    : false
  )
  vpc_ids = {
    for k, v in var.vpc_self_links
    : k => replace(v, "https://www.googleapis.com/compute/v1/", "")
  }
}

# Dedicated quota project for ngfw enterprise endpoints
module "ngfw-quota-project" {
  source = "../../../modules/project"
  name = (
    local.create_quota_project
    ? "net-ngfw-0"
    : var.ngfw_enterprise_config.quota_project_id
  )
  billing_account = (
    local.create_quota_project
    ? var.billing_account.id
    : null
  )
  parent = (
    local.create_quota_project
    ? var.folder_ids.networking
    : null
  )
  prefix = (
    local.create_quota_project
    ? var.prefix
    : null
  )
  project_create = (
    local.create_quota_project
    ? true
    : false
  )
  services = ["networksecurity.googleapis.com"]
}

resource "google_network_security_firewall_endpoint" "firewall_endpoint" {
  for_each           = toset(var.ngfw_enterprise_config.endpoint_zones)
  name               = "${var.prefix}-ngfw-endpoint-${each.key}"
  parent             = "organizations/${var.organization.id}"
  location           = each.value
  billing_project_id = module.ngfw-quota-project.id
}
