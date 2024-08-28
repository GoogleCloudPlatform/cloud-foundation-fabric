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

# tfdoc:file:description Sandbox stage resources.

locals {
  # FAST-specific IAM
  _sandbox_folder_fast_iam = !var.fast_features.sandbox ? {} : {
    "roles/logging.admin"                  = [module.branch-sandbox-sa[0].iam_email]
    "roles/owner"                          = [module.branch-sandbox-sa[0].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-sandbox-sa[0].iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-sandbox-sa[0].iam_email]
  }
  # deep-merge FAST-specific IAM with user-provided bindings in var.folder_iam
  _sandbox_folder_iam = merge(
    var.folder_iam.sandbox,
    {
      for role, principals in local._sandbox_folder_fast_iam :
      role => distinct(concat(principals, lookup(var.folder_iam.sandbox, role, [])))
    }
  )
}

module "branch-sandbox-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.sandbox ? 1 : 0
  parent = local.root_node
  name   = "Sandbox"
  iam    = local._sandbox_folder_iam
  factories_config = {
    org_policies = (
      var.root_node != null || var.factories_config.org_policies == null
      ? null
      : "${var.factories_config.org_policies}/sandbox"
    )
  }
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/sandbox"].id, null
    )
  }
}

module "branch-sandbox-gcs" {
  source     = "../../../modules/gcs"
  count      = var.fast_features.sandbox ? 1 : 0
  project_id = var.automation.project_id
  name       = "dev-resman-sbox-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-sandbox-sa[0].iam_email]
  }
}

module "branch-sandbox-sa" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_features.sandbox ? 1 : 0
  project_id   = var.automation.project_id
  name         = "dev-resman-sbox-0"
  display_name = "Terraform resman sandbox service account."
  prefix       = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
}
