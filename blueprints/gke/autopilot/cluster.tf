/**
 * Copyright 2023 Google LLC
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

module "cluster" {
  source     = "../../../modules/gke-cluster-autopilot"
  project_id = module.project.project_id
  name       = "cluster"
  location   = var.region
  vpc_config = {
    network                  = module.vpc.self_link
    subnetwork               = module.vpc.subnet_self_links["${var.region}/subnet-cluster"]
    secondary_range_names    = {}
    master_authorized_ranges = var.cluster_network_config.master_authorized_cidr_blocks
    master_ipv4_cidr_block   = var.cluster_network_config.master_cidr_block
  }
  # enable_features = {
  #   autopilot = true
  # }
  # monitoring_config = {
  #   # (Optional) control plane metrics
  #   enable_api_server_metrics         = true
  #   enable_controller_manager_metrics = true
  #   enable_scheduler_metrics          = true
  #   # (Optional) kube state metrics
  #   enable_daemonset_metrics   = true
  #   enable_deployment_metrics  = true
  #   enable_hpa_metrics         = true
  #   enable_pod_metrics         = true
  #   enable_statefulset_metrics = true
  #   enable_storage_metrics     = true
  # }
  # cluster_autoscaling = {
  #   auto_provisioning_defaults = {
  #     service_account = module.node_sa.email
  #   }
  # }
  release_channel = "RAPID"
  depends_on = [
    module.project
  ]
}

module "node_sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "sa-node"
}
