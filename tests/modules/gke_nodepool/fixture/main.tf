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

resource "google_service_account" "test" {
  project      = "my-project"
  account_id   = "gke-nodepool-test"
  display_name = "Test Service Account"
}

module "test" {
  source               = "../../../../modules/gke-nodepool"
  project_id           = "my-project"
  cluster_name         = "cluster-1"
  location             = "europe-west1-b"
  name                 = "nodepool-1"
  gke_version          = var.gke_version
  labels               = var.labels
  max_pods_per_node    = var.max_pods_per_node
  node_config          = var.node_config
  node_count           = var.node_count
  node_locations       = var.node_locations
  nodepool_config      = var.nodepool_config
  pod_range            = var.pod_range
  reservation_affinity = var.reservation_affinity
  service_account = {
    create = var.service_account_create
    email  = google_service_account.test.email
  }
  sole_tenant_nodegroup = var.sole_tenant_nodegroup
  tags                  = var.tags
  taints                = var.taints
}
