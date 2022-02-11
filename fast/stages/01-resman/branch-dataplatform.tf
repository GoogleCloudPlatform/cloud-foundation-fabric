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

# tfdoc:file:description Data Platform stages resources.

# top-level Data Platform folder and service account

module "branch-dp-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Dataplatform"
}

#TODO check if I can delete those modules, Would you create a data-platform TF to run dev/prod?
# module "branch-dp-sa" {
#   source      = "../../../modules/iam-service-account"
#   project_id  = var.automation_project_id
#   name        = "resman-dp-0"
#   description = "Terraform Data Platform production service account."
#   prefix      = local.prefixes.prod
# }

# module "branch-dp-gcs" {
#   source     = "../../../modules/gcs"
#   project_id = var.automation_project_id
#   name       = "dp-0"
#   prefix     = local.prefixes.prod
#   versioning = true
#   iam = {
#     "roles/storage.objectAdmin" = [module.branch-dp-sa.iam_email]
#   }
# }

# environment: development folder

module "branch-dp-dev-folder" {
  source = "../../../modules/folder"
  parent = module.branch-dp-folder.id
  # naming: environment descriptive name
  name = "Data Platform - Development"
  # environment-wide human permissions on the whole Data Platform environment
  group_iam = {}
  iam = {
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner" = [
      module.branch-dp-dev-sa.iam_email
    ]
    "roles/logging.admin" = [
      module.branch-dp-dev-sa.iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      module.branch-dp-dev-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-dp-dev-sa.iam_email
    ]
  }
}

module "branch-dp-dev-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.automation_project_id
  name       = "resman-dp-dev-0"
  # naming: environment in description
  description = "Terraform Data Platform development service account."
  prefix      = local.prefixes.dev
}

module "branch-dp-dev-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-dp-0"
  prefix     = local.prefixes.dev
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dp-dev-sa.iam_email]
  }
}

# environment: production folder

module "branch-dp-prod-folder" {
  source = "../../../modules/folder"
  parent = module.branch-dp-folder.id
  # naming: environment descriptive name
  name = "Data Platform - Production"
  # environment-wide human permissions on the whole Data Platform environment
  group_iam = {}
  iam = {
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner" = [
      module.branch-dp-prod-sa.iam_email
    ]
    "roles/logging.admin" = [
      module.branch-dp-prod-sa.iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      module.branch-dp-prod-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-dp-prod-sa.iam_email
    ]
  }
}

module "branch-dp-prod-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.automation_project_id
  name       = "resman-dp-0"
  # naming: environment in description
  description = "Terraform Data Platform production service account."
  prefix      = local.prefixes.prod
}

module "branch-dp-prod-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-dp-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dp-prod-sa.iam_email]
  }
}
