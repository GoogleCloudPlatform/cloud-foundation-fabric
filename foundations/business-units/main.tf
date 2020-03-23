/**
 * Copyright 2020 Google LLC
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

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

# Shared folder

module "shared-folder" {
  source = "../../modules/folders"
  parent = var.root_node
  names  = ["shared"]
}

# Terraform project

module "tf-project" {
  source               = "../../modules/project"
  name                 = "terraform"
  parent               = module.shared-folder.id
  prefix               = var.prefix
  billing_account      = var.billing_account_id
  iam_additive_members = { "roles/owner" = var.iam_terraform_owners }
  iam_additive_roles   = ["roles/owner"]
  services             = var.project_services
}

# Bootstrap Terraform state GCS bucket

module "tf-gcs-bootstrap" {
  source     = "../../modules/gcs"
  project_id = module.tf-project.project_id
  names      = ["tf-bootstrap"]
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
  parent          = var.root_node
  prefix          = var.prefix
  billing_account = var.billing_account_id
  iam_members = {
    "roles/bigquery.dataEditor" = [module.audit-log-sinks.writer_identities[0]]
    "roles/viewer"              = var.iam_audit_viewers
  }
  iam_roles = [
    "roles/bigquery.dataEditor",
    "roles/viewer"
  ]
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
  ])
}

# audit logs dataset and sink

module "audit-datasets" {
  source     = "../../modules/bigquery"
  project_id = module.audit-project.project_id
  datasets = {
    audit_export = {
      name        = "Audit logs export."
      description = "Terraform managed."
      location    = "EU"
      labels      = null
      options     = null
    }
  }
}

module "audit-log-sinks" {
  source = "../../modules/logging-sinks"
  parent = var.root_node
  destinations = {
    audit-logs = "bigquery.googleapis.com/projects/${module.audit-project.project_id}/datasets/${module.audit-datasets.names[0]}"
  }
  sinks = {
    audit-logs = var.audit_filter
  }
}

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
  iam_additive_members = {
    "roles/owner" = var.iam_shared_owners
  }
  iam_additive_roles = [
    "roles/owner"
  ]
  services = var.project_services
}

# Add further modules here for resources that are common to all business units
# like GCS buckets (used to hold shared assets), Container Registry, KMS, etc.
