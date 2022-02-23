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
  feature_binauthz = (
    var.member_features["configmanagement"]["binauthz"] == null
    ? { enabled = null }
    : var.member_features["configmanagement"]["binauthz"]
  )
  feature_config_sync = (
    var.member_features["configmanagement"]["config_sync"] == null
    ? {
      https_proxy               = null
      sync_repo                 = null
      sync_branch               = null
      sync_rev                  = null
      secret_type               = null
      gcp_service_account_email = null
      policy_dir                = null
      source_format             = null
    }
    : var.member_features["configmanagement"]["config_sync"]
  )
  feature_hierarchy_controller = (
    var.member_features["configmanagement"]["hierarchy_controller"] == null
    ? {
      enabled                            = null
      enable_pod_tree_labels             = null
      enable_hierarchical_resource_quota = null
    }
    : var.member_features["configmanagement"]["hierarchy_controller"]
  )
  feature_policy_controller = (
    var.member_features["configmanagement"]["policy_controller"] == null
    ? {
      enabled                    = null
      exemptable_namespaces      = null
      log_denies_enabled         = null
      referential_rules_enabled  = null
      template_library_installed = null
    }
    : var.member_features["configmanagement"]["policy_controller"]
  )
}

resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  for_each      = { for i, v in var.member_clusters : i => v }
  membership_id = each.key
  project       = var.project_id #hub project id
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/projects/${var.project_id}/locations/${each.value}/clusters/${each.key}"
    }
  }
}

resource "google_gke_hub_feature" "feature-configmanagement" {
  provider = google-beta
  count    = var.features.configmanagement ? 1 : 0
  project  = var.project_id
  name     = "configmanagement"
  location = "global"
}

resource "google_gke_hub_feature" "feature-mci" {
  provider = google-beta
  for_each = { for i, v in var.member_clusters : i => v }
  project  = var.project_id
  name     = "multiclusteringress"
  location = "global"
  spec {
    multiclusteringress {
      config_membership = google_gke_hub_membership.membership[each.key].id
    }
  }
}

resource "google_gke_hub_feature" "feature-mcs" {
  provider = google-beta
  count    = var.features.multiclusterservicediscovery ? 1 : 0
  project  = var.project_id
  name     = "multiclusterservicediscovery"
  location = "global"
}

resource "google_gke_hub_feature_membership" "feature_member" {
  provider   = google-beta
  for_each   = { for i, v in var.member_clusters : i => v }
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.feature-configmanagement[0].name
  membership = google_gke_hub_membership.membership[each.key].membership_id
  configmanagement {
    version = var.member_features.configmanagement.version

    config_sync {
      git {
        https_proxy               = local.feature_config_sync.https_proxy
        sync_repo                 = local.feature_config_sync.sync_repo
        sync_branch               = local.feature_config_sync.sync_branch
        sync_rev                  = local.feature_config_sync.sync_rev
        secret_type               = local.feature_config_sync.secret_type
        gcp_service_account_email = local.feature_config_sync.gcp_service_account_email
        policy_dir                = local.feature_config_sync.policy_dir
      }
      source_format = local.feature_config_sync.source_format
    }

    policy_controller {
      enabled                    = local.feature_policy_controller.enabled
      exemptable_namespaces      = local.feature_policy_controller.exemptable_namespaces
      log_denies_enabled         = local.feature_policy_controller.log_denies_enabled
      referential_rules_enabled  = local.feature_policy_controller.referential_rules_enabled
      template_library_installed = local.feature_policy_controller.template_library_installed
    }

    binauthz {
      enabled = local.feature_binauthz.enabled
    }

    hierarchy_controller {
      enabled                            = local.feature_hierarchy_controller.enabled
      enable_pod_tree_labels             = local.feature_hierarchy_controller.enable_pod_tree_labels
      enable_hierarchical_resource_quota = local.feature_hierarchy_controller.enable_hierarchical_resource_quota
    }
  }
}
