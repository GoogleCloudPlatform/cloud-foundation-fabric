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

module "gke-multitenant" {
  source             = "../../../../blueprints/gke/multitenant-fleet"
  billing_account_id = var.billing_account.id
  folder_id          = var.folder_ids.gke-dev
  project_id         = "gke-0"
  group_iam          = var.group_iam
  iam                = var.iam
  labels             = merge(var.labels, { environment = "dev" })
  prefix             = "${var.prefix}-dev"
  project_services   = var.project_services
  vpc_config = {
    host_project_id = var.host_project_ids.dev-spoke-0
    vpc_self_link   = var.vpc_self_links.dev-spoke-0
  }
  clusters                         = var.clusters
  nodepools                        = var.nodepools
  fleet_configmanagement_clusters  = var.fleet_configmanagement_clusters
  fleet_configmanagement_templates = var.fleet_configmanagement_templates
  fleet_features                   = var.fleet_features
  fleet_workload_identity          = var.fleet_workload_identity
}
