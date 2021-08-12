# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

# Terraform project

module "tf-project" {
  source          = "../../modules/project"
  name            = "terraform"
  parent          = var.root_node
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam_additive = {
    "roles/owner" = var.iam_terraform_owners
  }
  services = var.project_services
}

# per-environment service accounts

module "tf-service-accounts" {
  source     = "../../modules/iam-service-account"
  for_each   = var.environments
  project_id = module.tf-project.project_id
  name       = each.value
  prefix     = var.prefix
  iam_billing_roles = {
    (var.billing_account_id) = (
      var.iam_billing_config.grant ? local.sa_billing_account_role : []
    )
  }
  # folder roles are set in the folders module using authoritative bindings
  iam_organization_roles = {
    (local.organization_id) = concat(
      var.iam_billing_config.grant ? local.sa_billing_org_role : [],
      var.iam_xpn_config.grant ? local.sa_xpn_org_roles : []
    )
  }
  generate_key = var.service_account_keys
}

# bootstrap Terraform state GCS bucket

module "tf-gcs-bootstrap" {
  source     = "../../modules/gcs"
  project_id = module.tf-project.project_id
  name       = "tf-bootstrap"
  prefix     = "${var.prefix}-tf"
  location   = var.gcs_location
}

# per-environment Terraform state GCS buckets

module "tf-gcs-environments" {
  source     = "../../modules/gcs"
  for_each   = var.environments
  project_id = module.tf-project.project_id
  name       = each.value
  prefix     = "${var.prefix}-tf"
  location   = var.gcs_location
  iam = {
    "roles/storage.objectAdmin" = [module.tf-service-accounts[each.value].iam_email]
  }
}

###############################################################################
#                              Top-level folders                              #
###############################################################################

module "environment-folders" {
  source   = "../../modules/folder"
  for_each = var.environments
  parent   = var.root_node
  name     = each.value
  iam = {
    for role in local.folder_roles :
    (role) => [module.tf-service-accounts[each.value].iam_email]
  }
}

###############################################################################
#                              Audit log exports                              #
###############################################################################

# audit logs project

module "audit-project" {
  source          = "../../modules/project"
  name            = "audit"
  parent          = var.root_node
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam = {
    "roles/viewer" = var.iam_audit_viewers
  }
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
  ])
}

# audit logs dataset and sink

module "audit-dataset" {
  source        = "../../modules/bigquery-dataset"
  project_id    = module.audit-project.project_id
  id            = "audit_export"
  friendly_name = "Audit logs export."
  # disable delete on destroy for actual use
  options = {
    default_table_expiration_ms     = null
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = true
  }
}

# uncomment the next two modules to create the logging sinks

# module "root_org" {
#   count           = local.root_node_type == "organizations" ? 1 : 0
#   source          = "../../modules/organization"
#   organization_id = var.root_node
#   logging_sinks   = local.logging_sinks
# }

# module "root_folder" {
#   count         = local.root_node_type == "folders" ? 1 : 0
#   source        = "../../modules/folder"
#   id            = var.root_node
#   folder_create = false
#   logging_sinks = local.logging_sinks
# }


###############################################################################
#                    Shared resources (GCR, GCS, KMS, etc.)                   #
###############################################################################

# shared resources project
# see the README file for additional options on managing shared services

module "sharedsvc-project" {
  source          = "../../modules/project"
  name            = "sharedsvc"
  parent          = var.root_node
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam_additive = {
    "roles/owner" = var.iam_shared_owners
  }
  services = var.project_services
}

# Add further modules here for resources that are common to all environments
# like GCS buckets (used to hold shared assets), Container Registry, KMS, etc.
