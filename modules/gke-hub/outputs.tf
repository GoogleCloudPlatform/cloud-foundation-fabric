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

# output "cluster_ids" {
#   value = var.member_clusters
#   depends_on = [
#     google_gke_hub_membership.membership,
#     google_gke_hub_feature.configmanagement,
#     google_gke_hub_feature.mci,
#     google_gke_hub_feature.mcs,
#     google_gke_hub_feature_membership.feature_member,
#   ]
# }

output "foo" {
  value = {
    # _cluster_features = local._cluster_features
    # cluster_features  = local.cluster_features
    # mci = {
    #   for k, v in local.cluster_features :
    #   k => 1 if v.multi_cluster_ingress == true # don't fail on null
    # }
  }
}
