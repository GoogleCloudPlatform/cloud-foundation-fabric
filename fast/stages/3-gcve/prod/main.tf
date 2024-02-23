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

# tfdoc:file:description GKE multitenant for development environment.

module "gcve-pc" {
  source             = "../../../../blueprints/gcve/single-region-pc"
  billing_account_id = var.billing_account.id
  folder_id          = var.folder_ids.gcve-prod
  project_id         = "gcve-0"
  group_iam          = var.group_iam
  iam                = var.iam
  labels             = merge(var.labels, { environment = "prod" })
  prefix             = "${var.prefix}-dev"
  project_services   = var.project_services

  vmw_network_peerings = {
    prod-landing = {
      peer_network                        = var.vpc_self_links.prod-landing
      export_custom_routes                = false
      export_custom_routes_with_public_ip = false
      import_custom_routes                = false
      import_custom_routes_with_public_ip = false
      peer_to_vmware_engine_network       = false
    }
    prod-spoke = {
      peer_network                        = var.vpc_self_links.prod-spoke-0
      export_custom_routes                = false
      export_custom_routes_with_public_ip = false
      import_custom_routes                = false
      import_custom_routes_with_public_ip = false
      peer_to_vmware_engine_network       = false
    }
  }

  vmw_private_cloud_config = {
    cidr = "172.26.16.0/22"
    zone = "europe-west8-a"
    management_cluster_config = {
      name         = "mgmt-cluster"
      node_count   = 1
      node_type_id = "standard-72"
    }

  }
}
