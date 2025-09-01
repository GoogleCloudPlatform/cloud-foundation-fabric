/**
 * Copyright 2025 Google LLC
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
  _cluster_cm_config = flatten([
    for template, clusters in var.configmanagement_clusters : [
      for cluster in clusters : {
        cluster  = cluster
        template = lookup(var.configmanagement_templates, template, null)
      }
    ]
  ])
  cluster_cm_config = {
    for k in local._cluster_cm_config : k.cluster => k.template if(
      k.template != null &&
      var.features.configmanagement == true
    )
  }
  hub_features = {
    for k, v in var.features : k => v if v != null && v != false && v != ""
  }
}

resource "google_gke_hub_membership" "default" {
  provider      = google-beta
  for_each      = var.clusters
  project       = var.project_id
  location      = var.location
  membership_id = each.key
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${each.value}"
    }
  }
  dynamic "authority" {
    for_each = (
      contains(var.workload_identity_clusters, each.key) ? { 1 = 1 } : {}
    )
    content {
      issuer = "https://container.googleapis.com/v1/${var.clusters[each.key]}"
    }
  }
}

resource "google_gke_hub_feature" "default" {
  provider = google-beta
  for_each = local.hub_features
  project  = var.project_id
  name     = each.key
  location = "global"
  dynamic "spec" {
    for_each = each.key == "multiclusteringress" && each.value != null ? { 1 = 1 } : {}
    content {
      multiclusteringress {
        config_membership = google_gke_hub_membership.default[each.value].id
      }
    }
  }
  dynamic "fleet_default_member_config" {
    for_each = var.fleet_default_member_config != null ? { 1 = 1 } : {}
    content {
      dynamic "mesh" {
        for_each = var.fleet_default_member_config.mesh != null ? { 1 = 1 } : {}
        content {
          management = try(mesh.value.management, "MANAGEMENT_AUTOMATIC")
        }
      }

      dynamic "configmanagement" {
        for_each = var.fleet_default_member_config.configmanagement != null ? { 1 = 1 } : {}
        content {
          version = configmanagement.value.version

          dynamic "config_sync" {
            for_each = configmanagement.value.config_sync != null ? { 1 = 1 } : {}
            content {
              prevent_drift = config_sync.value.prevent_drift
              source_format = config_sync.value.source_format
              enabled       = config_sync.value.enabled

              dynamic "git" {
                for_each = config_sync.value.git != null ? { 1 = 1 } : {}
                content {
                  gcp_service_account_email = git.value.gcp_service_account_email
                  https_proxy               = git.value.https_proxy
                  policy_dir                = git.value.policy_dir
                  secret_type               = git.value.secret_type
                  sync_branch               = git.value.sync_branch
                  sync_repo                 = git.value.sync_repo
                  sync_rev                  = git.value.sync_rev
                  sync_wait_secs            = git.value.sync_wait_secs
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "google_gke_hub_feature_membership" "servicemesh" {
  provider            = google-beta
  for_each            = var.features.servicemesh ? var.clusters : {}
  project             = var.project_id
  location            = "global"
  feature             = google_gke_hub_feature.default["servicemesh"].name
  membership          = google_gke_hub_membership.default[each.key].membership_id
  membership_location = var.location

  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

resource "google_gke_hub_feature_membership" "default" {
  provider            = google-beta
  for_each            = local.cluster_cm_config
  project             = var.project_id
  location            = "global"
  feature             = google_gke_hub_feature.default["configmanagement"].name
  membership          = google_gke_hub_membership.default[each.key].membership_id
  membership_location = var.location

  configmanagement {
    version = each.value.version

    dynamic "config_sync" {
      for_each = each.value.config_sync == null ? {} : { 1 = 1 }
      content {
        prevent_drift = each.value.config_sync.prevent_drift
        source_format = each.value.config_sync.source_format
        enabled       = true
        dynamic "git" {
          for_each = (
            try(each.value.config_sync.git, null) == null ? {} : { 1 = 1 }
          )
          content {
            gcp_service_account_email = (
              each.value.config_sync.git.gcp_service_account_email
            )
            https_proxy    = each.value.config_sync.git.https_proxy
            policy_dir     = each.value.config_sync.git.policy_dir
            secret_type    = each.value.config_sync.git.secret_type
            sync_branch    = each.value.config_sync.git.sync_branch
            sync_repo      = each.value.config_sync.git.sync_repo
            sync_rev       = each.value.config_sync.git.sync_rev
            sync_wait_secs = each.value.config_sync.git.sync_wait_secs
          }
        }
      }
    }

    dynamic "hierarchy_controller" {
      for_each = each.value.hierarchy_controller == null ? {} : { 1 = 1 }
      content {
        enable_hierarchical_resource_quota = (
          each.value.hierarchy_controller.enable_hierarchical_resource_quota
        )
        enable_pod_tree_labels = (
          each.value.hierarchy_controller.enable_pod_tree_labels
        )
        enabled = true
      }
    }

    dynamic "policy_controller" {
      for_each = each.value.policy_controller == null ? {} : { 1 = 1 }
      content {
        audit_interval_seconds = (
          each.value.policy_controller.audit_interval_seconds
        )
        exemptable_namespaces = (
          each.value.policy_controller.exemptable_namespaces
        )
        log_denies_enabled = (
          each.value.policy_controller.log_denies_enabled
        )
        referential_rules_enabled = (
          each.value.policy_controller.referential_rules_enabled
        )
        template_library_installed = (
          each.value.policy_controller.template_library_installed
        )
        enabled = true
      }
    }
  }
}
