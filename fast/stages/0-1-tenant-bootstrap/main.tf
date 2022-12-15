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

locals {
  groups = {
    for k, v in var.tenant_config.groups :
    k => v == null ? null : "${v}@${var.organization.domain}"
  }
  locations = {
    for k, v in var.tenant_config.locations :
    k => v == null ? var.locations[k] : v
  }
  prefix   = join("-", compact([var.prefix, var.tenant_config.short_name]))
  tag_name = "${var.tag_names.tenant}/${var.tenant_config.short_name}"
}

module "tenant-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = var.tenant_config.descriptive_name
  # tag_bindings = {
  #   tenant = try(module.organization.tag_values[local.tag_name].id, null)
  # }
}

module "tenant-folder-iam" {
  source        = "../../../modules/folder"
  id            = module.tenant-folder.id
  folder_create = false
  group_iam = merge(var.tenant_config.group_iam, {
    (local.groups.gcp-admins) = [
      "roles/logging.admin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/compute.xpnAdmin"
    ]
  })
  iam = merge(var.tenant_config.iam, {
    "roles/logging.admin"                  = [module.automation-tf-resman-sa.iam_email]
    "roles/owner"                          = [module.automation-tf-resman-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.automation-tf-resman-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.automation-tf-resman-sa.iam_email]
    "roles/compute.xpnAdmin"               = [module.automation-tf-resman-sa.iam_email]
  })
  depends_on = [module.automation-project]
}
