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

# tfdoc:file:description GKE stage resources.

locals {
  gke_branch_group_iam = {
    (local.groups.gcp-devops) = [
      "roles/viewer",
      # ...
    ]
  }
}

# top-level GKE folder

module "branch-gke-folder" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/folder?ref=v12.0.0"
  parent = "organizations/${var.organization.id}"
  name   = "GKE"
}

# environment: development folder and automation resources

moved {
  from = module.branch-gke-env-folder["dev"]
  to   = module.branch-gke-dev-folder
}

module "branch-gke-dev-folder" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/folder?ref=v12.0.0"
  # naming: environment descriptive name
  name      = "Development"
  parent    = module.branch-gke-folder.id
  group_iam = local.gke_branch_group_iam
  iam = {
    "roles/logging.admin" = [
      module.branch-gke-dev-sa.iam_email
    ]
    "roles/owner" = [
      module.branch-gke-dev-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-dev-sa.iam_email
    ]
  }
}

moved {
  from = module.branch-gke-env-sa["dev"]
  to   = module.branch-gke-dev-sa
}

module "branch-gke-dev-sa" {
  source      = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v12.0.0"
  name        = "resman-gke-0"
  project_id  = var.automation_project_id
  description = "Terraform GKE development service account."
  prefix      = local.prefixes.dev
}

moved {
  from = module.branch-gke-gcs["dev"]
  to   = module.branch-gke-dev-gcs
}

module "branch-gke-dev-gcs" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gcs?ref=v12.0.0"
  name       = "resman-gke-0"
  project_id = var.automation_project_id
  prefix     = local.prefixes.dev
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-dev-sa.iam_email]
  }
}

# environment: production folder and automation resources

moved {
  from = module.branch-gke-env-folder["prod"]
  to   = module.branch-gke-prod-folder
}

module "branch-gke-prod-folder" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/folder?ref=v12.0.0"
  # naming: environment descriptive name
  name      = "Production"
  parent    = module.branch-gke-folder.id
  group_iam = local.gke_branch_group_iam
  iam = {
    "roles/logging.admin" = [
      module.branch-gke-prod-sa.iam_email
    ]
    "roles/owner" = [
      module.branch-gke-prod-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-prod-sa.iam_email
    ]
  }
}

moved {
  from = module.branch-gke-env-sa["prod"]
  to   = module.branch-gke-prod-sa
}

module "branch-gke-prod-sa" {
  source      = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v12.0.0"
  name        = "resman-gke-0"
  project_id  = var.automation_project_id
  description = "Terraform GKE production service account."
  prefix      = local.prefixes.prod
}

moved {
  from = module.branch-gke-gcs["prod"]
  to   = module.branch-gke-prod-gcs
}

module "branch-gke-prod-gcs" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gcs?ref=v12.0.0"
  name       = "resman-gke-0"
  project_id = var.automation_project_id
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-prod-sa.iam_email]
  }
}
