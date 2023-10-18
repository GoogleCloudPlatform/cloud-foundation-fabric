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

# tfdoc:file:description Lightweight tenant resources.

locals {
  tenant_iam = {
    for k, v in var.tenants : k => [
      "group:${v.admin_group_email}",
      module.tenant-self-iac-sa[k].iam_email
    ]
  }
}

# top-level "Tenants" folder

module "tenant-tenants-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Tenants"
  tag_bindings = {
    context = module.organization.tag_values["${var.tag_names.context}/tenant"].id
  }
}

# Tenant folders (top, core, self)

module "tenant-top-folder" {
  source   = "../../../modules/folder"
  for_each = var.tenants
  parent   = module.tenant-tenants-folder.id
  name     = each.value.descriptive_name
  group_iam = {
    (each.value.admin_group_email) = ["roles/browser"]
  }
}

module "tenant-top-folder-iam" {
  source        = "../../../modules/folder"
  for_each      = var.tenants
  id            = module.tenant-top-folder[each.key].id
  folder_create = false
  tag_bindings = {
    tenant = module.organization.tag_values["${var.tag_names.tenant}/${each.key}"].id
  }
  iam = merge(
    {
      "roles/cloudasset.owner"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/compute.xpnAdmin"               = [module.tenant-core-sa[each.key].iam_email]
      "roles/logging.admin"                  = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.projectCreator" = [module.tenant-core-sa[each.key].iam_email]
      "roles/resourcemanager.tagUser"        = [module.tenant-core-sa[each.key].iam_email]
    },
    {
      for k in var.tenants_config.top_folder_roles :
      k => local.tenant_iam[each.key]
    }
  )
}

module "tenant-core-folder" {
  source   = "../../../modules/folder"
  for_each = var.tenants
  parent   = module.tenant-top-folder[each.key].id
  name     = "${each.value.descriptive_name} - Core"
}

module "tenant-core-folder-iam" {
  source        = "../../../modules/folder"
  for_each      = var.tenants
  id            = module.tenant-core-folder[each.key].id
  folder_create = false
  iam = merge(
    {
      "roles/owner" = [
        module.tenant-core-sa[each.key].iam_email
      ]
      "roles/viewer" = local.tenant_iam[each.key]
    },
    {
      for k in var.tenants_config.core_folder_roles :
      k => local.tenant_iam[each.key]
    }
  )
}

module "tenant-self-folder" {
  source   = "../../../modules/folder"
  for_each = var.tenants
  parent   = module.tenant-top-folder[each.key].id
  name     = "${each.value.descriptive_name} - Tenant"
}

module "tenant-self-folder-iam" {
  source        = "../../../modules/folder"
  for_each      = var.tenants
  id            = module.tenant-self-folder[each.key].id
  folder_create = false
  iam = merge(
    {
      "roles/cloudasset.owner"               = local.tenant_iam[each.key]
      "roles/compute.xpnAdmin"               = local.tenant_iam[each.key]
      "roles/resourcemanager.folderAdmin"    = local.tenant_iam[each.key]
      "roles/resourcemanager.projectCreator" = local.tenant_iam[each.key]
      "roles/resourcemanager.tagUser"        = local.tenant_iam[each.key]
      "roles/owner"                          = local.tenant_iam[each.key]
    },
    {
      for k in var.tenants_config.tenant_folder_roles :
      k => local.tenant_iam[each.key]
    }
  )
}

# Tenant IaC resources (core)

module "tenant-core-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = var.tenants
  project_id  = var.automation.project_id
  name        = "tn-${each.key}-0"
  description = "Terraform service account for tenant ${each.key}."
  prefix      = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
}

module "tenant-core-gcs" {
  source        = "../../../modules/gcs"
  for_each      = var.tenants
  project_id    = var.automation.project_id
  name          = "tn-${each.key}-0"
  prefix        = var.prefix
  versioning    = true
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-core-sa[each.key].iam_email]
  }
}

# Tenant IaC project and resources (self)

module "tenant-self-iac-project" {
  source   = "../../../modules/project"
  for_each = var.tenants
  billing_account = (
    each.value.billing_account != null
    ? each.value.billing_account
    : var.billing_account.id
  )
  name   = "${each.key}-iac-core-0"
  parent = module.tenant-self-folder[each.key].id
  prefix = var.prefix
  group_iam = {
    (each.value.admin_group_email) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
  services = [
    "accesscontextmanager.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sourcerepo.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com"
  ]
}

module "tenant-self-iac-gcs-outputs" {
  source        = "../../../modules/gcs"
  for_each      = var.tenants
  project_id    = module.tenant-self-iac-project[each.key].project_id
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  name          = "${each.key}-iac-outputs-0"
  prefix        = var.prefix
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.tenant-core-sa[each.key].iam_email]
  }
}

module "tenant-self-iac-gcs-state" {
  source        = "../../../modules/gcs"
  for_each      = var.tenants
  project_id    = module.tenant-self-iac-project[each.key].project_id
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  name          = "${each.key}-iac-0"
  prefix        = var.prefix
  versioning    = true
}

module "tenant-self-iac-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = var.tenants
  project_id  = module.tenant-self-iac-project[each.key].project_id
  name        = "${each.key}-iac-0"
  description = "Terraform automation service account."
  prefix      = var.prefix
  iam_storage_roles = {
    (module.tenant-self-iac-gcs-outputs[each.key].name) = [
      "roles/storage.admin"
    ]
    (module.tenant-self-iac-gcs-state[each.key].name) = [
      "roles/storage.admin"
    ]
  }
}

