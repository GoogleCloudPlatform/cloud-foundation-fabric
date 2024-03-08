# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "gke-cluster-standard" {
  source              = "./fabric/modules/gke-cluster-standard"
  project_id          = var.project_id
  name                = "cluster"
  location            = "${var.region}-b"
  deletion_protection = false
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
    master_authorized_ranges = {
      internal-vms = "10.0.0.0/8"
    }
    master_ipv4_cidr_block = "192.168.0.0/28"
  }
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = false
  }
  enable_features = {
    dataplane_v2        = true
    fqdn_network_policy = true
    workload_identity   = true
  }
}

module "gke-nodepool" {
  source       = "./fabric/modules/gke-nodepool"
  project_id   = var.project_id
  cluster_name = module.gke-cluster-standard.name
  location     = "${var.region}-b"
  name         = "gke-nodepool"
  nodepool_config = {
    autoscaling = {
      max_node_count = 2
      min_node_count = 1
    }
  }
}
