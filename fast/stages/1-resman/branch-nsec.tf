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

# tfdoc:file:description Network security stage resources.

# TODO: remove in v35.0.0

moved {
  from = module.branch-nsec-sa
  to   = module.branch-nsec-sa[0]
}

moved {
  from = module.branch-nsec-r-sa
  to   = module.branch-nsec-r-sa[0]
}

moved {
  from = module.branch-nsec-gcs
  to   = module.branch-nsec-gcs[0]
}

# automation service account

module "branch-nsec-sa" {
  source                 = "../../../modules/iam-service-account"
  count                  = var.fast_features.nsec ? 1 : 0
  project_id             = var.automation.project_id
  name                   = "prod-resman-nsec-0"
  display_name           = "Terraform resman network security service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-nsec-sa-cicd[0].iam_email, null)
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

module "branch-nsec-r-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.nsec ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-nsec-0r"
  display_name = "Terraform resman network security service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-nsec-r-sa-cicd[0].iam_email, null)
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

module "branch-nsec-gcs" {
  source     = "../../../modules/gcs"
  count      = var.fast_features.nsec ? 1 : 0
  project_id = var.automation.project_id
  name       = "prod-resman-nsec-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-nsec-sa[0].iam_email]
    "roles/storage.objectViewer" = [module.branch-nsec-r-sa[0].iam_email]
  }
}
