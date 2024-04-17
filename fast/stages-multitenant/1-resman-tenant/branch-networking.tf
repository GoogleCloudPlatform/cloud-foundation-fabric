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

# tfdoc:file:description Networking stage resources.

module "branch-network-folder" {
  source = "../../../modules/folder"
  parent = module.root-folder.id
  name   = "Networking"
  iam_by_principals = local.principals.gcp-network-admins == null ? {} : {
    (local.principals.gcp-network-admins) = [
      # add any needed roles for resources/services not managed via Terraform,
      # or replace editor with ~viewer if no broad resource management needed
      # e.g.
      #   "roles/compute.networkAdmin",
      #   "roles/dns.admin",
      #   "roles/compute.securityAdmin",
      "roles/editor",
    ]
  }
  iam = {
    "roles/logging.admin"                  = [local.automation_sas_iam.networking]
    "roles/owner"                          = [local.automation_sas_iam.networking]
    "roles/resourcemanager.folderAdmin"    = [local.automation_sas_iam.networking]
    "roles/resourcemanager.projectCreator" = [local.automation_sas_iam.networking]
    "roles/compute.xpnAdmin"               = [local.automation_sas_iam.networking]
  }
  tag_bindings = {
    context = var.tags.values["${var.tags.names.context}/networking"]
  }
}

module "branch-network-prod-folder" {
  source = "../../../modules/folder"
  parent = module.branch-network-folder.id
  name   = "Production"
  iam = {
    (local.custom_roles.service_project_network_admin) = concat(
      local.branch_optional_sa_lists.dp-prod,
      local.branch_optional_sa_lists.gke-prod,
      local.branch_optional_sa_lists.pf-prod,
    )
  }
  tag_bindings = {
    environment = var.tags.values["${var.tags.names.environment}/production"]
  }
}

module "branch-network-dev-folder" {
  source = "../../../modules/folder"
  parent = module.branch-network-folder.id
  name   = "Development"
  iam = {
    (local.custom_roles.service_project_network_admin) = concat(
      local.branch_optional_sa_lists.dp-dev,
      local.branch_optional_sa_lists.gke-dev,
      local.branch_optional_sa_lists.pf-dev,
    )
  }
  tag_bindings = {
    environment = var.tags.values["${var.tags.names.environment}/development"]
  }
}

# automation service account and bucket

module "branch-network-sa" {
  source                 = "../../../modules/iam-service-account"
  project_id             = var.automation.project_id
  name                   = "networking-0"
  prefix                 = var.prefix
  service_account_create = var.test_skip_data_sources
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-network-sa-cicd[0].iam_email, null)
    ])
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.admin"]
  }
}

module "branch-network-gcs" {
  source        = "../../../modules/gcs"
  project_id    = var.automation.project_id
  name          = "prod-resman-net-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [local.automation_sas_iam.networking]
  }
}
