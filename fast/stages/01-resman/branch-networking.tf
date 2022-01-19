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

# tfdoc:file:description Networking stage resources.

module "branch-network-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Networking"
  group_iam = {
    (local.groups.gcp-network-admins) = [
      # add any needed roles for resources/services not managed via Terraform,
      # or replace editor with ~viewer if no broad resource management needed
      # e.g.
      #   "roles/compute.networkAdmin",
      #   "roles/dns.admin",
      #   "roles/compute.securityAdmin",
      "roles/editor",
    ]
  }
  iam = {
    "roles/logging.admin"                  = [module.branch-network-sa.iam_email]
    "roles/owner"                          = [module.branch-network-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-network-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-network-sa.iam_email]
  }
}

module "branch-network-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "resman-networking-0"
  description = "Terraform resman networking service account."
  prefix      = local.prefixes.prod
}

module "branch-network-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-networking-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-network-sa.iam_email]
  }
}
