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

module "branch-security-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Security"
  group_iam = {
    (local.groups.gcp-security-admins) = [
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
    "roles/logging.admin"                  = [module.branch-security-sa.iam_email]
    "roles/owner"                          = [module.branch-security-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-security-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-security-sa.iam_email]
  }
}

module "branch-security-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "resman-security-0"
  description = "Terraform resman security service account."
  prefix      = local.prefixes.prod
}

module "branch-security-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-security-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-security-sa.iam_email]
  }
}
