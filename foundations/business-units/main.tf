/**
 * Copyright 2021 Google LLC
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
  logging_sinks = {
    audit-logs = {
      type             = "bigquery"
      destination      = module.audit-dataset.id
      filter           = var.audit_filter
      iam              = true
      include_children = true
    }
  }
  root_node_type = split("/", var.root_node)[0]
}

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

# Shared folder

module "shared-folder" {
  source = "../../modules/folder"
  parent = var.root_node
  name   = "shared"
}

# Terraform project

module "tf-project" {
  source          = "../../modules/project"
  name            = "terraform"
  parent          = module.shared-folder.id
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam_additive = {
    for name in var.iam_terraform_owners : (name) => ["roles/owner"]
  }
  services = var.project_services
}

# Bootstrap Terraform state GCS bucket

module "tf-gcs-bootstrap" {
  source     = "../../modules/gcs"
  project_id = module.tf-project.project_id
  name       = "tf-bootstrap"
  prefix     = "${var.prefix}-tf"
  location   = var.gcs_defaults.location
}

###############################################################################
#                                Business units                               #
###############################################################################

module "bu-business-intelligence" {
  source                = "../../modules/folders-unit"
  name                  = "Business Intelligence"
  short_name            = "bi"
  automation_project_id = module.tf-project.project_id
  billing_account_id    = var.billing_account_id
  environments          = var.environments
  gcs_defaults          = var.gcs_defaults
  organization_id       = var.organization_id
  root_node             = var.root_node
  prefix                = var.prefix
  # extra variables from the folders-unit module can be used here to grant
  # IAM roles to the bu users, configure the automation service accounts, etc.
  # iam_roles             = ["viewer"]
  # iam_members           = { viewer = ["user:user@example.com"] }
}

module "bu-machine-learning" {
  source                = "../../modules/folders-unit"
  name                  = "Machine Learning"
  short_name            = "ml"
  automation_project_id = module.tf-project.project_id
  billing_account_id    = var.billing_account_id
  environments          = var.environments
  gcs_defaults          = var.gcs_defaults
  organization_id       = var.organization_id
  root_node             = var.root_node
  prefix                = var.prefix
  # extra variables from the folders-unit module can be used here to grant
  # IAM roles to the bu users, configure the automation service accounts, etc.
}

###############################################################################
#                              Audit log exports                              #
###############################################################################

# Audit logs project

module "audit-project" {
  source          = "../../modules/project"
  name            = "audit"
  parent          = module.shared-folder.id
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

# Shared resources project

module "shared-project" {
  source          = "../../modules/project"
  name            = "shared"
  parent          = module.shared-folder.id
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam_additive = {
    for name in var.iam_shared_owners : (name) => ["roles/owner"]
  }
  services = var.project_services
}

# Add further modules here for resources that are common to all business units
# like GCS buckets (used to hold shared assets), Container Registry, KMS, etc.
