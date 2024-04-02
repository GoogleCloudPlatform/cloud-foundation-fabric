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
  source             = "../../../../blueprints/gcve/pc-minimal"
  billing_account_id = var.billing_account.id
  folder_id          = var.folder_ids.gcve-prod
  project_id         = "gcve-0"
  groups             = local.groups_gcve
  iam                = var.iam
  labels             = merge(var.labels, { environment = "prod" })
  prefix             = "${var.prefix}-prod"
  project_services   = var.project_services

  network_peerings = {
    prod-spoke-ven = {
      peer_network           = local.peer_network.prod-spoke-0
      peer_project_id        = var.host_project_ids.prod-spoke-0
      configure_peer_network = true
      custom_routes = {
        export_to_peer   = true
        import_from_peer = true
        export_to_ven    = true
        import_from_ven  = true
      }
    }
  }

  private_cloud_configs = var.private_cloud_configs
}
