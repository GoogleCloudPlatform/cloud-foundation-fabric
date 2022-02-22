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
  count    = var.features["configmanagement"] ? 1 : 0
  provider = google-beta
  project  = var.project_id
  name     = "configmanagement"
  location = "global"
}

resource "google_gke_hub_feature" "feature-mci" {
  # count    = var.features["multiclusteringress"] ? 1 : 0
  for_each = { for i, v in var.member_clusters : i => v }
  provider = google-beta
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
  count    = var.features["multiclusterservicediscovery"] ? 1 : 0
  provider = google-beta
  project  = var.project_id
  name     = "multiclusterservicediscovery"
  location = "global"
}

resource "google_gke_hub_feature_membership" "feature_member" {
  provider = google-beta
  project  = var.project_id

  for_each   = { for i, v in var.member_clusters : i => v }
  location   = "global"
  feature    = google_gke_hub_feature.feature-configmanagement[0].name
  membership = google_gke_hub_membership.membership[each.key].membership_id
  configmanagement {
    version = var.member_features["configmanagement"].version

    config_sync {
      git {
        https_proxy               = var.member_features["configmanagement"]["config_sync"].http_proxy
        sync_repo                 = var.member_features["configmanagement"]["config_sync"].sync_repo
        sync_branch               = var.member_features["configmanagement"]["config_sync"].sync_branch
        sync_rev                  = var.member_features["configmanagement"]["config_sync"].sync_rev
        secret_type               = var.member_features["configmanagement"]["config_sync"].secret_type
        gcp_service_account_email = var.member_features["configmanagement"]["config_sync"].gcp_service_account_email
        policy_dir                = var.member_features["configmanagement"]["config_sync"].policy_dir
      }
      source_format = var.member_features["configmanagement"]["config_sync"].source_format
    }

    policy_controller {
      enabled                    = var.member_features["configmanagement"]["policy_controller"].enabled
      exemptable_namespaces      = var.member_features["configmanagement"]["policy_controller"].exemptable_namespaces
      log_denies_enabled         = var.member_features["configmanagement"]["policy_controller"].log_denies_enabled
      referential_rules_enabled  = var.member_features["configmanagement"]["policy_controller"].referential_rules_enabled
      template_library_installed = var.member_features["configmanagement"]["policy_controller"].template_library_installed # https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library
    }

    binauthz {
      enabled = var.member_features["configmanagement"]["binauthz"].enabled
    }
    hierarchy_controller {
      enabled                            = var.member_features["configmanagement"]["hierarchy_controller"].enabled
      enable_pod_tree_labels             = var.member_features["configmanagement"]["hierarchy_controller"].enable_pod_tree_labels
      enable_hierarchical_resource_quota = var.member_features["configmanagement"]["hierarchy_controller"].enable_hierarchical_resource_quota
    }
  }
}
