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

# tfdoc:file:description Gitlab stage resources.

module "branch-gitlab-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.gitlab ? 1 : 0
  parent = "organizations/${var.organization.id}"
  name   = "Gitlab"
  group_iam = local.groups.gcp-devops == null ? {} : {
    (local.groups.gcp-devops) = [
      # owner and viewer roles are broad and might grant unwanted access
      # replace them with more selective custom roles for production deployments
      "roles/editor"
    ]
  }
  iam = {
    # read-write (apply) automation service account
    "roles/logging.admin"                  = [module.branch-gitlab-sa.0.iam_email]
    "roles/owner"                          = [module.branch-gitlab-sa.0.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-gitlab-sa.0.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-gitlab-sa.0.iam_email]
    "roles/compute.xpnAdmin"               = [module.branch-gitlab-sa.0.iam_email]
    # read-only (plan) automation service account
    "roles/viewer"                       = [module.branch-gitlab-r-sa.0.iam_email]
    "roles/resourcemanager.folderViewer" = [module.branch-gitlab-r-sa.0.iam_email]
  }
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/gitlab"].id, null
    )
  }
}

# automation service account

module "branch-gitlab-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gitlab ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-gitlab-0"
  display_name = "Terraform resman gitlab service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-gitlab-sa-cicd.0.iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

# automation read-only service account

module "branch-gitlab-r-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.gitlab ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-gitlab-0r"
  display_name = "Terraform resman gitlab service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-gitlab-r-sa-cicd.0.iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "branch-gitlab-gcs" {
  source        = "../../../modules/gcs"
  count         = var.fast_features.gitlab ? 1 : 0
  project_id    = var.automation.project_id
  name          = "prod-resman-gitlab-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-gitlab-sa.0.iam_email]
    "roles/storage.objectViewer" = [module.branch-gitlab-r-sa.0.iam_email]
  }
}
