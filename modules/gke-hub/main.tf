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

locals {
  _cluster_features = flatten([
    for config, clusters in var.member_features : [
      for cluster in clusters : { cluster = cluster, config = config }
    ]
  ])

}

resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  for_each      = var.member_clusters
  project       = var.project_id
  membership_id = each.key
  endpoint {
    gke_cluster {
      resource_link = each.value
    }
  }
}

# resource "google_gke_hub_feature" "mci" {
#   provider = google-beta
#   for_each = var.features.mc_ingress ? var.member_clusters : {}
#   project  = var.project_id
#   name     = "multiclusteringress"
#   location = "global"
#   spec {
#     multiclusteringress {
#       config_membership = google_gke_hub_membership.membership[each.key].id
#     }
#   }
# }

# resource "google_gke_hub_feature" "servicemesh" {
#   provider = google-beta
#   for_each = var.features.servicemesh ? { 1 = 1 } : {}
#   project  = var.project_id
#   name     = "servicemesh"
#   location = "global"
# }
