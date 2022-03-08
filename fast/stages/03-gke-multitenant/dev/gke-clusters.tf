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
  clusters = {
    for name, config in var.clusters :
    name => merge(config, {
      overrides = coalesce(config.overrides, var.cluster_defaults)
    })
  }
}

module "gke-cluster" {
  source                   = "../../../../modules/gke-cluster"
  for_each                 = local.clusters
  name                     = each.key
  project_id               = module.gke-project-0.project_id
  description              = each.value.description
  location                 = each.value.location
  network                  = var.vpc_self_links.dev-spoke-0
  subnetwork               = each.value.net.subnet
  secondary_range_pods     = each.value.net.pods
  secondary_range_services = each.value.net.services
  labels                   = each.value.labels
  addons = {
    cloudrun_config                       = each.value.overrides.cloudrun_config
    dns_cache_config                      = true
    http_load_balancing                   = true
    gce_persistent_disk_csi_driver_config = true
    horizontal_pod_autoscaling            = true
    config_connector_config               = true
    kalm_config                           = false
    # enable only if enable_dataplane_v2 is changed to false below
    network_policy_config = false
    istio_config = {
      enabled = false
      tls     = false
    }
  }
  # change these here for all clusters if absolutely needed
  # authenticator_security_group = var.authenticator_security_group
  enable_dataplane_v2         = true
  enable_l4_ilb_subsetting    = false
  enable_intranode_visibility = true
  enable_shielded_nodes       = true
  workload_identity           = true
  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = each.value.net.master_range
    master_global_access    = true
  }
  dns_config = each.value.dns_domain == null ? null : {
    cluster_dns        = "CLOUD_DNS"
    cluster_dns_scope  = "VPC_SCOPE"
    cluster_dns_domain = "${each.key}.${var.dns_domain}"
  }
  logging_config    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_config = ["SYSTEM_COMPONENTS", "WORKLOADS"]

  # if you don't have compute.networks.updatePeering in the host
  # project, comment out the next line and ask your network admin to
  # create the peering for you
  peering_config = {
    export_routes = true
    import_routes = false
    project_id    = var.host_project_ids.dev-spoke-0
  }
  resource_usage_export_config = {
    enabled = true
    dataset = module.gke-dataset-resource-usage.dataset_id
  }
  # TODO: the attributes below are "primed" from project-level defaults
  #       in locals, merge defaults with cluster-level stuff
  # TODO(jccb): change fabric module
  database_encryption = (
    each.value.overrides.database_encryption_key == null ? {
      enabled  = false
      state    = null
      key_name = null
      } : {
      enabled  = true
      state    = "ENCRYPTED"
      key_name = each.value.overrides.database_encryption_key
    }
  )
  default_max_pods_per_node   = each.value.overrides.max_pods_per_node
  enable_binary_authorization = each.value.overrides.enable_binary_authorization
  master_authorized_ranges    = each.value.overrides.master_authorized_ranges
  pod_security_policy         = each.value.overrides.pod_security_policy
  release_channel             = each.value.overrides.release_channel
  vertical_pod_autoscaling    = each.value.overrides.vertical_pod_autoscaling
  # dynamic "cluster_autoscaling" {
  #   for_each = each.value.cluster_autoscaling == null ? {} : { 1 = 1 }
  #   content {
  #     enabled    = true
  #     cpu_min    = each.value.cluster_autoscaling.cpu_min
  #     cpu_max    = each.value.cluster_autoscaling.cpu_max
  #     memory_min = each.value.cluster_autoscaling.memory_min
  #     memory_max = each.value.cluster_autoscaling.memory_max
  #   }
  # }

}
