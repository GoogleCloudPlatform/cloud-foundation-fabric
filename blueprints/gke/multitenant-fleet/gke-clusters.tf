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
  source      = "../../../modules/gke-cluster"
  for_each    = local.clusters
  name        = each.key
  project_id  = module.gke-project-0.project_id
  description = each.value.description
  location    = each.value.location
  vpc_config = {
    network    = var.vpc_config.vpc_self_link
    subnetwork = each.value.net.subnet
    secondary_range_names = {
      pods     = each.value.net.pods
      services = each.value.net.services
    }
    master_authorized_ranges = each.value.overrides.master_authorized_ranges
  }
  labels = each.value.labels
  enable_addons = {
    cloudrun                       = each.value.overrides.cloudrun_config
    config_connector               = true
    dns_cache                      = true
    gce_persistent_disk_csi_driver = true
    gcp_filestore_csi_driver       = each.value.overrides.gcp_filestore_csi_driver_config
    gke_backup_agent               = false
    horizontal_pod_autoscaling     = true
    http_load_balancing            = true
  }
  enable_features = {
    cloud_dns = var.dns_domain == null ? null : {
      cluster_dns        = "CLOUD_DNS"
      cluster_dns_scope  = "VPC_SCOPE"
      cluster_dns_domain = "${each.key}.${var.dns_domain}"
    }
    database_encryption = (
      each.value.overrides.database_encryption_key == null
      ? null
      : {
        state    = "ENCRYPTED"
        key_name = each.value.overrides.database_encryption_key
      }
    )
    dataplane_v2         = true
    groups_for_rbac      = var.authenticator_security_group
    intranode_visibility = true
    pod_security_policy  = each.value.overrides.pod_security_policy
    resource_usage_export = {
      dataset = module.gke-dataset-resource-usage.dataset_id
    }
    shielded_nodes           = true
    vertical_pod_autoscaling = each.value.overrides.vertical_pod_autoscaling
    workload_identity        = true
  }
  private_cluster_config = {
    enable_private_endpoint = true
    master_ipv4_cidr_block  = each.value.net.master_range
    master_global_access    = true
    peering_config = var.peering_config == null ? null : {
      export_routes = var.peering_config.export_routes
      import_routes = var.peering_config.import_routes
      project_id    = var.vpc_config.host_project_id
    }
  }
  logging_config    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_config = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  max_pods_per_node = each.value.overrides.max_pods_per_node
  release_channel   = each.value.overrides.release_channel
}
