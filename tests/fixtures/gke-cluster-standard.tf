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
  access_config = {
    ip_access = {
      authorized_ranges = {
        internal-vms = "10.0.0.0/8"
      }
    }
  }
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  enable_features = {
    dataplane_v2        = true
    fqdn_network_policy = true
    shielded_nodes      = true
    workload_identity   = true
  }
  node_config = {
    service_account               = module.gke-service-accounts.email
    kubelet_readonly_port_enabled = false
  }
  node_pool_auto_config = {
    network_tags                  = ["foo"] # to avoid perma-diff
    kubelet_readonly_port_enabled = false
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
  service_account = { email = module.gke-service-accounts.email }
  node_config = {
    shielded_instance_config = {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }
}

module "gke-service-accounts" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "gke-sa"
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
