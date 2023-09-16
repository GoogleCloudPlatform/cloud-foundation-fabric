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
  source     = "../../../modules/gke-cluster-standard"
  project_id = module.project.project_id
  name       = "cluster"
  location   = var.region
  vpc_config = {
    network                  = module.vpc.self_link
    subnetwork               = module.vpc.subnet_self_links["${var.region}/subnet-apigee"]
    secondary_range_names    = {}
    master_authorized_ranges = var.cluster_network_config.master_authorized_cidr_blocks
    master_ipv4_cidr_block   = var.cluster_network_config.master_cidr_block
  }
  max_pods_per_node = 32
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = false
  }
  enable_features = {
    workload_identity = true
  }
}

module "apigee-data-nodepool" {
  source       = "../../../modules/gke-nodepool"
  project_id   = module.project.project_id
  cluster_name = module.cluster.name
  location     = var.region
  name         = "apigee-data-nodepool"
  nodepool_config = {
    autoscaling = {
      min_node_count = 1
      max_node_count = 3
    }
  }
  node_config = {
    machine_type = var.cluster_machine_type
  }
  service_account = {
    create = true
  }
  tags = ["node"]
}

module "apigee-runtime-nodepool" {
  source       = "../../../modules/gke-nodepool"
  project_id   = module.project.project_id
  cluster_name = module.cluster.name
  location     = var.region
  name         = "apigee-runtime-nodepool"
  nodepool_config = {
    autoscaling = {
      min_node_count = 1
      max_node_count = 3
    }
  }
  node_config = {
    machine_type = var.cluster_machine_type
  }
  service_account = {
    create = true
  }
  tags = ["node"]
}
