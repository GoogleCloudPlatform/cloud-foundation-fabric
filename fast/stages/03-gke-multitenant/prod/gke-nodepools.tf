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
  nodepools = merge([
    for cluster, nodepools in var.nodepools : {
      for nodepool, config in nodepools :
      "${cluster}/${nodepool}" => merge(config, {
        name      = nodepool
        cluster   = cluster
        overrides = coalesce(config.overrides, var.nodepool_defaults)
      })
    }
  ]...)
}

module "gke_1_nodepool" {
  source             = "../../../../modules/gke-nodepool"
  for_each           = local.nodepools
  name               = each.value.name
  project_id         = module.gke-project-0.project_id
  cluster_name       = module.gke-cluster[each.value.cluster].name
  location           = module.gke-cluster[each.value.cluster].location
  initial_node_count = each.value.node_count
  node_machine_type  = each.value.node_type
  # TODO(jccb): can we use spot instances here?
  node_preemptible = each.value.preemptible

  node_count = each.value.node_count
  # node_count = (
  #   each.value.autoscaling_config == null ? each.value.node_count : null
  # )
  # dynamic "autoscaling_config" {
  #   for_each = each.value.autoscaling_config == null ? {} : { 1 = 1 }
  #   content {
  #     min_node_count = each.value.autoscaling_config.min_node_count
  #     max_node_count = each.value.autoscaling_config.max_node_count
  #   }
  # }

  # overrides
  node_locations    = each.value.overrides.node_locations
  max_pods_per_node = each.value.overrides.max_pods_per_node
  node_image_type   = each.value.overrides.image_type
  node_tags         = each.value.overrides.node_tags
  node_taints       = each.value.overrides.node_taints

  management_config = {
    auto_repair  = true
    auto_upgrade = true
  }

  node_service_account_create = true
}
