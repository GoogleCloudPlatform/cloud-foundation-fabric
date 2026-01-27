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

# tfdoc:file:description GKE clusters.

locals {
  clusters = {
    test-00 = {
      description = "Cluster test 0"
      location    = "europe-west1"
    }
  }
  _nodepools = {
    test-00 = {
      test-00-nodepool-01 = {
        node_count = { initial = 1 }
      }
    }
  }
  nodepools = merge([
    for cluster, nodepools in local._nodepools : {
      for nodepool, config in nodepools :
      "${cluster}/${nodepool}" => merge(config, {
        name    = nodepool
        cluster = cluster
      })
    }
  ]...)
}

module "gke-cluster" {
  source     = "../../../modules/gke-cluster-standard"
  for_each   = local.clusters
  name       = each.key
  project_id = module.gke-project-0.project_id
  access_config = {
    dns_access = true
    ip_access = {
      disable_public_endpoint = true
    }
    private_nodes = true
  }
  cluster_autoscaling = try(each.value.cluster_autoscaling, null)
  default_nodepool = {
    remove_pool        = false
    initial_node_count = 1
  }
  description = try(each.value.description, null)
  enable_features = {
    binary_authorization = true
    database_encryption = {
      state    = "ENCRYPTED"
      key_name = var.gke_kms_key
    }
    groups_for_rbac      = "gke-security-groups@google.com"
    intranode_visibility = true
    rbac_binding_config = {
      enable_insecure_binding_system_unauthenticated : false
      enable_insecure_binding_system_authenticated : false
    }
    shielded_nodes = true
    upgrade_notifications = {
      event_types  = ["SECURITY_BULLETIN_EVENT", "UPGRADE_AVAILABLE_EVENT", "UPGRADE_INFO_EVENT", "UPGRADE_EVENT"]
      kms_key_name = var.gke_kms_key
    }
    workload_identity = true
  }

  enable_addons = try(each.value.enable_addons, {
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
  })
  issue_client_certificate = try(each.value.issue_client_certificate, false)
  labels                   = try(each.value.labels, {})
  location                 = each.value.location
  logging_config = try(each.value.logging_config, {
    enable_system_logs    = true
    enable_workloads_logs = true
  })
  maintenance_config = try(each.value.maintenance_config, {
    daily_window_start_time = "03:00"
  })
  max_pods_per_node  = try(each.value.max_pods_per_node, 110)
  min_master_version = try(each.value.min_master_version, null)
  monitoring_config = try(each.value.monitoring_config, {
    enable_managed_prometheus = true
    enable_system_metrics     = true
  })
  node_locations  = try(each.value.node_locations, [])
  release_channel = try(each.value.release_channel, null)
  vpc_config = {
    network    = var.vpc_self_links["dev"]
    subnetwork = var.subnet_self_links["dev"]["europe-west1/dev-default"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  deletion_protection = false
  node_config = {
    boot_disk_kms_key = var.gke_kms_key
    service_account   = module.gke-nodes-service-account.email
  }
}

module "gke-nodepool" {
  source            = "../../../modules/gke-nodepool"
  for_each          = local.nodepools
  name              = each.value.name
  project_id        = module.gke-project-0.project_id
  cluster_name      = module.gke-cluster[each.value.cluster].name
  location          = module.gke-cluster[each.value.cluster].location
  gke_version       = try(each.value.gke_version, null)
  k8s_labels        = try(each.value.k8s_labels, {})
  max_pods_per_node = try(each.value.max_pods_per_node, null)
  node_config = {
    sandbox_config_gvisor = true
    boot_disk_kms_key     = var.gke_kms_key
    metadata = {
      disable-legacy-endpoints = "true"
    }
    shielded_instance_config = {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }
  node_count           = try(each.value.node_count, { initial = 1 })
  nodepool_config      = try(each.value.nodepool_config, null)
  network_config       = try(each.value.network_config, null)
  reservation_affinity = try(each.value.reservation_affinity, null)
  service_account = (
    try(each.value.service_account, null) == null
    ? { email = module.gke-nodes-service-account.email }
    : each.value.service_account
  )
  sole_tenant_nodegroup = try(each.value.sole_tenant_nodegroup, null)
  tags                  = try(each.value.tags, [])
  taints                = try(each.value.taints, {})
}
