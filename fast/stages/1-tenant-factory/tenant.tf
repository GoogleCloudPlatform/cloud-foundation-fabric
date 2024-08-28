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
  contacts = (
    each.value.fast_config != null
    ? {}
    : {
      (split(":", each.value.admin_principal)[1]) = ["ALL"]
    }
  )
}

module "tenant-folder-iam" {
  source        = "../../../modules/folder"
  for_each      = local.tenants
  id            = module.tenant-folder[each.key].id
  folder_create = false
  iam = {
    "roles/logging.admin" = compact([
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email,
      try(module.tenant-automation-tf-resman-sa[each.key].iam_email, null)
    ])
    "roles/owner" = [
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email
    ]
    "roles/resourcemanager.folderAdmin" = compact([
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email,
      try(module.tenant-automation-tf-resman-sa[each.key].iam_email, null)
    ])
    "roles/resourcemanager.projectCreator" = compact([
      each.value.admin_principal,
      module.tenant-sa[each.key].iam_email,
      try(module.tenant-automation-tf-resman-sa[each.key].iam_email, null)
    ])
    "roles/serviceusage.serviceUsageViewer" = compact([
      try(module.tenant-automation-tf-resman-r-sa[each.key].iam_email, null)
    ])
    "roles/resourcemanager.tagAdmin" = compact([
      try(module.tenant-automation-tf-resman-sa[each.key].iam_email, null)
    ])
    "roles/resourcemanager.tagUser" = compact([
      try(module.tenant-automation-tf-resman-sa[each.key].iam_email, null)
    ])
    "roles/viewer" = compact([
      try(module.tenant-automation-tf-resman-r-sa[each.key].iam_email, null)
    ])
  }
  iam_bindings = each.value.fast_config == null ? {} : {
    tenant_iam_admin_conditional = {
      members = [module.tenant-automation-tf-resman-sa[each.key].iam_email]
      role    = "roles/resourcemanager.folderIamAdmin"
      condition = {
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'", [
            "roles/accesscontextmanager.policyAdmin",
            "roles/cloudasset.viewer",
            "roles/compute.orgFirewallPolicyAdmin",
            "roles/compute.xpnAdmin",
            var.custom_roles["tenant_network_admin"]
          ]))
        )
        title       = "tenant_automation_sa_delegated_grants"
        description = "Automation service account delegated grants."
      }
    }
  }
  depends_on = [module.tenant-automation-project]
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
  source     = "../../../modules/gcs"
  for_each   = local.tenants
  project_id = var.automation.project_id
  name       = "tenant-${each.key}-0"
  prefix     = var.prefix
  location   = each.value.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-sa[each.key].iam_email]
  }
}
