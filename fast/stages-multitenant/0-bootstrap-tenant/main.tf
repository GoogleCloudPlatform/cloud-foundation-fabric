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

locals {
  gcs_storage_class = (
    length(split("-", local.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  groups = {
    for k, v in var.tenant_config.groups :
    k => v == null ? null : "${v}@${var.organization.domain}"
  }
  fast_features = {
    for k, v in var.tenant_config.fast_features :
    k => v == null ? var.fast_features[k] : v
  }
  locations = {
    for k, v in var.tenant_config.locations :
    k => v == null || v == [] ? var.locations[k] : v
  }
  prefix = join("-", compact([var.prefix, var.tenant_config.short_name]))
  resman_sa = (
    var.test_principal == null
    ? data.google_client_openid_userinfo.resman-sa.0.email
    : var.test_principal
  )
}

data "google_client_openid_userinfo" "resman-sa" {
  count = var.test_principal == null ? 1 : 0
}

module "tenant-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = var.tenant_config.descriptive_name
  logging_sinks = {
    for name, attrs in var.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
    }
  }
  tag_bindings = {
    tenant = try(
      module.organization.tag_values["${var.tag_names.tenant}/${var.tenant_config.short_name}"].id,
      null
    )
  }
}

module "tenant-folder-iam" {
  source        = "../../../modules/folder"
  id            = module.tenant-folder.id
  folder_create = false
  group_iam = merge(var.group_iam, {
    (local.groups.gcp-admins) = [
      "roles/logging.admin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/compute.xpnAdmin"
    ]
  })
  iam = merge(var.iam, {
    "roles/compute.xpnAdmin" = [
      module.automation-tf-resman-sa.iam_email,
      module.automation-tf-resman-sa-stage2-3["networking"].iam_email
    ]
    "roles/logging.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/owner" = [
      module.automation-tf-resman-sa.iam_email
    ]
  })
  iam_additive = var.iam_additive
  depends_on   = [module.automation-project]
}
