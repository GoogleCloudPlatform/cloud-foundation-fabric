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

# tfdoc:file:description Per-tenant resources.

module "tenant-folder" {
  source   = "../../../modules/folder"
  for_each = local.tenants
  parent   = module.tenant-core-folder[each.key].id
  name     = each.value.descriptive_name
  iam = {
    "roles/logging.admin" = [
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email
    ]
    "roles/owner" = [
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email
    ]
  }
  contacts = { (split(":", each.value.admin_principal)[1]) = ["ALL"] }
}

# automation service account

module "tenant-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.tenants
  project_id   = var.automation.project_id
  name         = "tenant-${each.key}-0"
  display_name = "Terraform tenant ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [each.value.admin_principal]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
}

# automation bucket

module "tenant-gcs" {
  source        = "../../../modules/gcs"
  for_each      = local.tenants
  project_id    = var.automation.project_id
  name          = "tenant-${each.key}-0"
  prefix        = var.prefix
  location      = each.value.locations.gcs
  storage_class = each.value.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-sa[each.key].iam_email]
  }
}
