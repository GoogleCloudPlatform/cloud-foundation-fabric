
locals {
  config_management_wid_sa_email = (
    var.config_management.workload_identity_sa == null
    ? (
      length(module.gke-wid-platform-sa[0]) > 0
      ? module.gke-wid-platform-sa[0].email
      : null
    )
    : var.config_management.workload_identity_sa
  )
  config_management_repository_url = (
    var.config_management.repository_url == null
    ? (
      length(module.gke-config-management-platform-repo[0]) > 0
      ? module.gke-config-management-platform-repo[0].url
      : null
    )
    : var.config_management.repository_url
  )
}


#add the cluster to the gke hub
resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  for_each      = local.clusters
  membership_id = each.key
  project       = module.gke-project-0.project_id
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/projects/${module.gke-project-0.project_id}/locations/${each.value.location}/clusters/${each.key}"
    }
  }
}
#enable configmanagement feature on the the clusters registered into the hub
resource "google_gke_hub_feature" "feature" {
  provider = google-beta
  project  = module.gke-project-0.project_id
  name     = "configmanagement"
  location = "global"
}

# # sa used by configsync, via WorkloadID to pull code from the repo
module "gke-wid-platform-sa" {
  count        = var.config_management.workload_identity_sa == null ? 1 : 0
  source       = "../../../../modules/iam-service-account"
  project_id   = module.gke-project-0.project_id
  name         = "gke-wid-platform-sa"
  generate_key = false
  iam = {
    "roles/iam.workloadIdentityUser" = ["serviceAccount:${module.gke-project-0.project_id}.svc.id.goog[config-management-system/root-reconciler]"]
  }
}

# #source repository #FIX(dmarzi) - APIs activation, a data resource could be needed
module "gke-config-management-platform-repo" {
  count      = var.config_management.repository_url == null ? 1 : 0
  source     = "../../../../modules/source-repository"
  project_id = module.gke-project-0.project_id
  name       = "gke-config-management-platform-repo"
  iam = {
    "roles/source.reader" = ["serviceAccount:${local.config_management_wid_sa_email}"]
  }
}

#configure configmanagement feature for the hub
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature_membership
resource "google_gke_hub_feature_membership" "feature_member" {
  project    = module.gke-project-0.project_id
  for_each   = local.clusters
  location   = "global"
  feature    = google_gke_hub_feature.feature.name
  membership = google_gke_hub_membership.membership[each.key].membership_id
  configmanagement {
    version = "1.10.0"

    config_sync {
      # enabled = true
      git {
        sync_repo                 = local.config_management_repository_url
        sync_branch               = "main"
        secret_type               = "gcpserviceaccount"
        gcp_service_account_email = local.config_management_wid_sa_email
        policy_dir                = "configsync"
      }
      source_format = "hierarchy"
    }

    policy_controller {
      enabled                    = true
      log_denies_enabled         = true
      exemptable_namespaces      = ["cos-auditd", "config-management-monitoring", "config-management-system"]
      template_library_installed = true # https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library
    }
  }

  provider = google-beta
}
