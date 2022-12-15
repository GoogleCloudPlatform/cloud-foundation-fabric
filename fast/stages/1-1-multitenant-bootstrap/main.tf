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
    for k, v in var.tenant_configs : k => {
      for kk, vv in v.groups :
      kk => vv == null ? null : "${vv}@${var.organization.domain}"
    }
  }
  locations = {
    for k, v in var.tenant_configs : k => {
      for kk, vv in v.locations :
      kk => vv == null ? var.locations[kk] : vv
    }
  }
  prefixes = {
    for k, v in var.tenant_configs :
    k => join("-", compact([var.prefix, k]))
  }
}

module "tenant-folder" {
  source   = "../../../modules/folder"
  for_each = var.tenant_configs
  parent   = "organizations/${var.organization.id}"
  name     = each.value.descriptive_name
  tag_bindings = {
    tenant = try(module.organization.tag_values[each.key].id, null)
  }
}

module "tenant-folder-iam" {
  source        = "../../../modules/folder"
  for_each      = var.tenant_configs
  id            = module.tenant-folder[each.key].id
  folder_create = false
  group_iam = merge(each.value.group_iam, {
    (local.groups[each.key].gcp-admins) = [
      "roles/logging.admin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/compute.xpnAdmin"
    ]
  })
  iam = merge(each.value.iam, {
    "roles/logging.admin"                  = [module.automation-tf-resman-sa[each.key].iam_email]
    "roles/owner"                          = [module.automation-tf-resman-sa[each.key].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.automation-tf-resman-sa[each.key].iam_email]
    "roles/resourcemanager.projectCreator" = [module.automation-tf-resman-sa[each.key].iam_email]
    "roles/compute.xpnAdmin"               = [module.automation-tf-resman-sa[each.key].iam_email]
  })
  depends_on = [module.automation-project]
}
