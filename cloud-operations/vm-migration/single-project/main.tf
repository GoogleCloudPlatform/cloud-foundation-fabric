# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "m4ce-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account_id
  name            = var.m4ce_project_name
  parent          = var.m4ce_project_root

  services = [
    "vmmigration.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "networkconnectivity.googleapis.com",
  ]

  project_create = var.m4ce_project_create

  auto_create_network = var.m4ce_project_create

  iam_additive = {
    "roles/iam.serviceAccountKeyAdmin" = concat(var.m4ce_admin_users, [module.m4ce-service-account.iam_email]),
    "roles/iam.serviceAccountCreator"  = concat(var.m4ce_admin_users, [module.m4ce-service-account.iam_email]),
    "roles/vmmigration.admin"          = concat(var.m4ce_admin_users, [module.m4ce-service-account.iam_email]),
    "roles/vmmigration.viewer"         = var.m4ce_viewer_users
  }
}

module "m4ce-service-account" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.m4ce-project.project_id
  name         = "gcp-m4ce-sa"
  generate_key = true
}
