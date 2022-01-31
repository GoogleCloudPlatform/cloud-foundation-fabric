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

# tfdoc:file:description Security stage resources.

module "branch-gke-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "GKE"
  group_iam = {
    (local.groups.gcp-gke-admins) = [
      # add any needed roles for resources/services not managed via Terraform,
      # e.g.
      # "roles/bigquery.admin",
      # "roles/cloudasset.owner",
      # "roles/cloudkms.admin",
      # "roles/logging.admin",
      # "roles/secretmanager.admin",
      # "roles/storage.admin",
      "roles/viewer"
    ]
  }
  iam = {
    "roles/logging.admin"                  = [module.branch-gke-sa.iam_email]
    "roles/owner"                          = [module.branch-gke-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-gke-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-gke-sa.iam_email]
  }
}

module "branch-gke-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "resman-gke-0"
  description = "Terraform gke security service account."
  prefix      = local.prefixes.prod
}

module "branch-gke-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-gke-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-sa.iam_email]
  }
}
