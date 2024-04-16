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

# tfdoc:file:description Security stage resources.

module "branch-security-folder" {
  source = "../../../modules/folder"
  parent = module.root-folder.id
  name   = "Security"
  iam_by_principals = local.principals.gcp-security-admins == null ? {} : {
    (local.principals.gcp-security-admins) = [
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
    "roles/logging.admin"                  = [local.automation_sas_iam.security]
    "roles/owner"                          = [local.automation_sas_iam.security]
    "roles/resourcemanager.folderAdmin"    = [local.automation_sas_iam.security]
    "roles/resourcemanager.projectCreator" = [local.automation_sas_iam.security]
  }
  tag_bindings = {
    context = var.tags.values["${var.tags.names.context}/security"]
  }
}

# automation service account and bucket

module "branch-security-sa" {
  source                 = "../../../modules/iam-service-account"
  project_id             = var.automation.project_id
  name                   = "security-0"
  prefix                 = var.prefix
  service_account_create = var.test_skip_data_sources
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-security-sa-cicd[0].iam_email, null)
    ])
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.admin"]
  }
}

module "branch-security-gcs" {
  source        = "../../../modules/gcs"
  project_id    = var.automation.project_id
  name          = "prod-resman-sec-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [local.automation_sas_iam.security]
  }
}
