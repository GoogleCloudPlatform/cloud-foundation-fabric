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

# tfdoc:file:description GKE multitenant stage resources.

# top-level gke folder

module "branch-gke-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "GKE"
  # iam = {
  #   "roles/logging.admin"                  = [module.branch-gke-sa.iam_email]
  #   "roles/owner"                          = [module.branch-gke-sa.iam_email]
  #   "roles/resourcemanager.folderAdmin"    = [module.branch-gke-sa.iam_email]
  #   "roles/resourcemanager.projectCreator" = [module.branch-gke-sa.iam_email]
  # }
}

# GKE-level folders, service accounts and buckets for each individual environment

module "branch-gke-multitenant-prod-folder" {
  source = "../../../modules/folder"
  parent = module.branch-gke-folder.id
  name   = "prod"
  iam = {
    "roles/owner" = [
      module.branch-gke-multitenant-prod-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-multitenant-prod-sa.iam_email
    ]
  }
}

module "branch-gke-multitenant-prod-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "gke-prod-0"
  description = "Terraform gke multitenant prod service account."
  prefix      = var.prefix
  iam = {
    # FIXME(jccb): who should we use here?
    "roles/iam.serviceAccountTokenCreator" = ["group:${local.groups.gcp-devops}"]
  }
}

module "branch-gke-multitenant-prod-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "gke-prod-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-multitenant-prod-sa.iam_email]
  }
}


module "branch-gke-multitenant-dev-folder" {
  source = "../../../modules/folder"
  parent = module.branch-gke-folder.id
  name   = "dev"
  iam = {
    "roles/owner" = [
      module.branch-gke-multitenant-dev-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-multitenant-dev-sa.iam_email
    ]
  }
}

module "branch-gke-multitenant-dev-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "gke-dev-0"
  description = "Terraform gke multitenant dev service account."
  prefix      = var.prefix
  iam = {
    # FIXME(jccb): who should we use here?
    "roles/iam.serviceAccountTokenCreator" = ["group:${local.groups.gcp-devops}"]
  }
}

module "branch-gke-multitenant-dev-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "gke-dev-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-multitenant-dev-sa.iam_email]
  }
}
