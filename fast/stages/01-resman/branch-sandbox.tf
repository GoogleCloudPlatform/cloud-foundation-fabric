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

# tfdoc:file:description Sandbox stage resources.

module "branch-sandbox-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Sandbox"
  iam = {
    "roles/logging.admin"                  = [module.branch-sandbox-sa.iam_email]
    "roles/owner"                          = [module.branch-sandbox-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-sandbox-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-sandbox-sa.iam_email]
  }
  policy_boolean = {
    "constraints/sql.restrictPublicIp" = false
  }
  policy_list = {
    "constraints/compute.vmExternalIpAccess" = {
      inherit_from_parent = false
      suggested_value     = null
      status              = true
      values              = []
    }
  }
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/sandbox"].id, null
    )
  }
}

module "branch-sandbox-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "dev-resman-sbox-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-sandbox-sa.iam_email]
  }
}

module "branch-sandbox-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation.project_id
  name        = "dev-resman-sbox-0"
  description = "Terraform resman sandbox service account."
  prefix      = var.prefix
}
