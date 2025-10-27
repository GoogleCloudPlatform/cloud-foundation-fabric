/**
 * Copyright 2025 Google LLC
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

locals {
  location = reverse(split("/", var.network_config.subnetwork))[2]
}

module "cluster" {
  source                 = "../../../modules/workstation-cluster"
  project_id             = var.project_id
  id                     = var.id
  location               = local.location
  network_config         = var.network_config
  private_cluster_config = var.private_cluster_config
  factories_config       = var.factories_config
  context = merge(var.context, {
    iam_principals = merge(var.context.iam_principals, {
      for k, v in var.service_accounts : "service_accounts/${k}" => v.email
    })
  })
}

module "ws-addresses" {
  source     = "../../../modules/net-address"
  count      = var.network_config.psc_endpoint_address != null ? 1 : 0
  project_id = var.project_id
  psc_addresses = {
    ws-cluster-0 = {
      address          = var.network_config.psc_endpoint_address
      subnet_self_link = var.network_config.subnetwork
      region           = local.location
      service_attachment = {
        psc_service_attachment_link = module.cluster.service_attachment_uri
      }
    }
  }
}
