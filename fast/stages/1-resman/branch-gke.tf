/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description GKE multitenant stage resources.

module "branch-gke-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.gke ? 1 : 0
  parent = local.root_node
  name   = "GKE"
  iam    = var.folder_iam.gke
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/gke"].id, null
    )
  }
}

module "branch-gke-dev-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.gke ? 1 : 0
  parent = module.branch-gke-folder[0].id
  name   = "Development"
  iam = {
    # read-write (apply) automation service account
    "roles/owner"                          = [module.branch-gke-dev-sa[0].iam_email]
    "roles/logging.admin"                  = [module.branch-gke-dev-sa[0].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-gke-dev-sa[0].iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-gke-dev-sa[0].iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-gke-dev-sa[0].iam_email]
    # read-only (plan) automation service account
    "roles/viewer"                       = [module.branch-gke-dev-r-sa[0].iam_email]
    "roles/resourcemanager.folderViewer" = [module.branch-gke-dev-r-sa[0].iam_email]
  }
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

module "branch-gke-prod-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.gke ? 1 : 0
  parent = module.branch-gke-folder[0].id
  name   = "Production"
  iam = {
    # read-write (apply) automation service account
    "roles/owner"                          = [module.branch-gke-prod-sa[0].iam_email]
    "roles/logging.admin"                  = [module.branch-gke-prod-sa[0].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-gke-prod-sa[0].iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-gke-prod-sa[0].iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-gke-prod-sa[0].iam_email]
    # read-only (plan) automation service account
    "roles/viewer"                       = [module.branch-gke-prod-r-sa[0].iam_email]
    "roles/resourcemanager.folderViewer" = [module.branch-gke-prod-r-sa[0].iam_email]
  }
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.environment}/production"].id,
      null
    )
  }
}

# automation service accounts

module "branch-gke-dev-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gke ? 1 : 0
  project_id   = var.automation.project_id
  name         = "dev-resman-gke-0"
  display_name = "Terraform gke multitenant dev service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      [local.principals.gcp-devops],
      compact([
        try(module.branch-gke-dev-sa-cicd[0].iam_email, null)
      ])
    )
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "branch-gke-prod-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gke ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-gke-0"
  display_name = "Terraform gke multitenant prod service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      [local.principals.gcp-devops],
      compact([
        try(module.branch-gke-prod-sa-cicd[0].iam_email, null)
      ])
    )
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

# automation read-only service accounts

module "branch-gke-dev-r-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gke ? 1 : 0
  project_id   = var.automation.project_id
  name         = "dev-resman-gke-0r"
  display_name = "Terraform gke multitenant development service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-gke-dev-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

module "branch-gke-prod-r-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gke ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-gke-0r"
  display_name = "Terraform gke multitenant production service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-gke-prod-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation buckets

module "branch-gke-dev-gcs" {
  source     = "../../../modules/gcs"
  count      = var.fast_features.gke ? 1 : 0
  project_id = var.automation.project_id
  name       = "dev-resman-gke-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-gke-dev-sa[0].iam_email]
    "roles/storage.objectViewer" = [module.branch-gke-dev-r-sa[0].iam_email]
  }
}

module "branch-gke-prod-gcs" {
  source     = "../../../modules/gcs"
  count      = var.fast_features.gke ? 1 : 0
  project_id = var.automation.project_id
  name       = "prod-resman-gke-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-gke-prod-sa[0].iam_email]
    "roles/storage.objectViewer" = [module.branch-gke-prod-r-sa[0].iam_email]
  }
}
