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


# config_management = {
#     workload_identity_sa = "gke-project-0-wid-1-sa@dc02-prod-gke-clusters-0.iam.gserviceaccount.com"
#     repository_url = null
# }

locals {

  hub_config = {
    for k, config in var.hub_config :
    k => merge(config, {
      config_sync       = coalesce(config.config_sync, var.config_sync_defaults)
      policy_controller = coalesce(config.policy_controller, var.policy_controller_defaults)
    })
  }

  config_sync_sa_email = (
    var.hub_config.config_sync.workload_identity_sa == null
    ? (
      length(module.gke-workload-identity-platform-sa[0]) > 0
      ? module.gke-workload-identity-platform-sa[0].email
      : null
    )
    : var.hub_config.config_sync.workload_identity_sa
  )
  config_sync_repository_url = (
    var.hub_config.config_sync.repository_url == null
    ? (
      length(module.gke-config-management-platform-repo[0]) > 0
      ? module.gke-config-management-platform-repo[0].url
      : null
    )
    : var.hub_config.config_sync.repository_url
  )
}

# add the cluster to the gke hub
resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  for_each      = { for i, v in var.hub_config.clusters : i => v }
  membership_id = each.value.name
  project       = var.project_id
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/projects/${var.project_id}/locations/${each.value.location}/clusters/${each.value.name}"
    }
  }
}

#enable configmanagement feature on the the clusters registered into the hub
resource "google_gke_hub_feature" "feature" {
  count    = var.hub_config.config_sync == null ? 0 : 1
  provider = google-beta
  project  = var.project_id
  name     = "configmanagement"
  location = "global"
}

# sa used by configsync, via WorkloadID to pull code from the repo
module "gke-workload-identity-platform-sa" {
  count        = var.hub_config.config_sync == null ? 1 : 0 #TOFIX .workload_identity_sa
  source       = "../../modules/iam-service-account"
  project_id   = var.project_id
  name         = "gke-wid-platform-sa"
  generate_key = false
  iam = {
    "roles/iam.workloadIdentityUser" = ["serviceAccount:${var.project_id}.svc.id.goog[config-management-system/root-reconciler]"]
  }
}

# # #source repository
module "gke-config-management-platform-repo" {
  count      = var.hub_config.config_sync == null ? 1 : 0 #TOFIX .repository_url
  source     = "../../modules/source-repository"
  project_id = var.project_id
  name       = "gke-config-management-platform-repo"
  iam = {
    "roles/source.reader" = ["serviceAccount:${local.config_sync_sa_email}"]
  }
}

# configure configmanagement feature for the hub
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature_membership
resource "google_gke_hub_feature_membership" "feature_member" {
  provider = google-beta
  project  = var.project_id

  for_each   = { for i, v in var.hub_config.clusters : i => v }
  location   = "global"
  feature    = google_gke_hub_feature.feature[0].name
  membership = google_gke_hub_membership.membership[each.value.name].membership_id
  configmanagement {
    version = "1.10.0"
    # enabled = true

    dynamic "config_sync" {
      for_each = var.hub_config.config_sync
      content {
        git {
          sync_repo                 = local.config_sync_repository_url
          sync_branch               = var.hub_config.config_sync.repository_branch
          secret_type               = "gcpserviceaccount" #TOFIX
          gcp_service_account_email = local.config_sync_sa_email
          policy_dir                = var.hub_config.config_sync.repository_policy_dir
        }
        source_format = var.hub_config.config_sync.repository_source_format #"hierarchy"
      }
    }

    dynamic "policy_controller" {
      for_each = var.hub_config.policy_controller
      content {
        enabled                    = true
        log_denies_enabled         = var.hub_config.policy_controller.enable_log_denies
        exemptable_namespaces      = var.hub_config.policy_controller.exemptable_namespaces
        template_library_installed = var.hub_config.policy_controller.enable_template_library # https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library
      }
    }
  }
}
