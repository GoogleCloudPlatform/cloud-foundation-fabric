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

# tfdoc:file:description GKE hub configuration.

locals {
  fleet_clusters = var.fleet_config == null ? {} : {
    for k, v in var.clusters : k => v.configmanagement_template
    if v.fleet_config.register == true
  }
  fleet_mcs_enabled = (
    try(
      var.fleet_config.enable_features.multiclusterservicediscovery, false
    ) == true
  )
}

module "gke-hub" {
  source     = "../../../modules/gke-hub"
  count      = var.fleet_config != null ? 1 : 0
  project_id = module.gke-project-0.project_id
  clusters = {
    for k, v in local.fleet_clusters : k => module.gke-cluster[k].id
  }
  features                   = var.fleet_config.enable_features
  configmanagement_templates = var.fleet_configmanagement_templates
  configmanagement_clusters = {
    for k, v in local.fleet_clusters : v => k...
  }
  workload_identity_clusters = (
    var.fleet_config.use_workload_identity ? keys(local.fleet_clusters) : []
  )
  depends_on = [
    module.gke-nodepool
  ]
}
