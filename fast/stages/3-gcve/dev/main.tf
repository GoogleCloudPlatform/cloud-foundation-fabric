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

# tfdoc:file:description GCVE private cloud for development environment.
locals {
  groups_gcve = {
    for k, v in var.groups_gcve : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
  peer_network = {
    for k, v in var.vpc_self_links : k => (
      trimprefix(v, "https://www.googleapis.com/compute/v1/")
    )
  }
}

module "gcve-pc" {
  source             = "../../../../blueprints/gcve/single-region-pc"
  billing_account_id = var.billing_account.id
  folder_id          = var.folder_ids.gcve-dev
  project_id         = "gcve-1"
  groups             = local.groups_gcve
  iam                = var.iam
  labels             = merge(var.labels, { environment = "dev" })
  prefix             = "${var.prefix}-dev"
  project_services   = var.project_services

  ven_peerings = {
    dev-spoke = {
      peer_network                        = local.peer_network.dev-spoke-0
      export_custom_routes                = false
      export_custom_routes_with_public_ip = false
      import_custom_routes                = false
      import_custom_routes_with_public_ip = false
      peer_to_vmware_engine_network       = false
    }
  }

  user_peerings = {
    dev-ven = {
      peer_network                        = local.peer_network.dev-spoke-0
      project_id                          = var.host_project_ids.dev-spoke-0
      export_custom_routes                = false
      export_custom_routes_with_public_ip = false
      import_custom_routes                = false
      import_custom_routes_with_public_ip = false
    }
  }

  private_cloud_configs = var.private_cloud_configs
}
