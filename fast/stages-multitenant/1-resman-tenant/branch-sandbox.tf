/**
 * Copyright 2023 Google LLC
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
  count  = var.fast_features.sandbox ? 1 : 0
  parent = module.root-folder.id
  name   = "Sandbox"
  iam = {
    "roles/logging.admin"                  = [local.automation_sas_iam.sandbox]
    "roles/owner"                          = [local.automation_sas_iam.sandbox]
    "roles/resourcemanager.folderAdmin"    = [local.automation_sas_iam.sandbox]
    "roles/resourcemanager.projectCreator" = [local.automation_sas_iam.sandbox]
  }
  org_policies = {
    "sql.restrictPublicIp"       = { rules = [{ enforce = false }] }
    "compute.vmExternalIpAccess" = { rules = [{ allow = { all = true } }] }
  }
  tag_bindings = {
    context = var.tags.values["${var.tags.names.context}/sandbox"]
  }
}

module "branch-sandbox-gcs" {
  source        = "../../../modules/gcs"
  count         = var.fast_features.sandbox ? 1 : 0
  project_id    = var.automation.project_id
  name          = "dev-resman-sbox-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [local.automation_sas_iam.sandbox]
  }
}
