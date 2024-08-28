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

# tfdoc:file:description Project factory stage resources.

# automation service accounts

moved {
  from = module.branch-pf-sa[0]
  to   = module.branch-pf-sa
}

module "branch-pf-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "resman-pf-0"
  display_name = "Terraform project factory main service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

moved {
  from = module.branch-pf-dev-sa[0]
  to   = module.branch-pf-dev-sa
}

module "branch-pf-dev-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "dev-resman-pf-0"
  display_name = "Terraform project factory development service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-dev-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

moved {
  from = module.branch-pf-prod-sa[0]
  to   = module.branch-pf-prod-sa
}

module "branch-pf-prod-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "prod-resman-pf-0"
  display_name = "Terraform project factory production service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-prod-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

# automation read-only service accounts

moved {
  from = module.branch-pf-r-sa[0]
  to   = module.branch-pf-r-sa
}

module "branch-pf-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "resman-pf-0r"
  display_name = "Terraform project factory main service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

moved {
  from = module.branch-pf-dev-r-sa[0]
  to   = module.branch-pf-dev-r-sa
}

module "branch-pf-dev-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "dev-resman-pf-0r"
  display_name = "Terraform project factory development service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-dev-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

moved {
  from = module.branch-pf-prod-r-sa[0]
  to   = module.branch-pf-prod-r-sa
}

module "branch-pf-prod-r-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "prod-resman-pf-0r"
  display_name = "Terraform project factory production service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-pf-prod-r-sa-cicd[0].iam_email, null)
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

moved {
  from = module.branch-pf-gcs[0]
  to   = module.branch-pf-gcs
}

module "branch-pf-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "resman-pf-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-pf-sa.iam_email]
    "roles/storage.objectViewer" = [module.branch-pf-r-sa.iam_email]
  }
}

moved {
  from = module.branch-pf-dev-gcs[0]
  to   = module.branch-pf-dev-gcs
}

module "branch-pf-dev-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "dev-resman-pf-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-pf-dev-sa.iam_email]
    "roles/storage.objectViewer" = [module.branch-pf-dev-r-sa.iam_email]
  }
}

moved {
  from = module.branch-pf-prod-gcs[0]
  to   = module.branch-pf-prod-gcs
}

module "branch-pf-prod-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "prod-resman-pf-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-pf-prod-sa.iam_email]
    "roles/storage.objectViewer" = [module.branch-pf-prod-r-sa.iam_email]
  }
}
