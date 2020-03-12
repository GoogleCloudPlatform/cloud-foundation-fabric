# Copyright 2019 Google LLC
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

# TODO(averbukh): simplify log-sink parameters once https://github.com/terraform-google-modules/terraform-google-log-export/issues/28 is done.

locals {
  parent_numeric_id             = element(split("/", var.root_node), 1)
  log_sink_parent_resource_type = element(split("/", var.root_node), 0) == "organizations" ? "organization" : "folder"
  log_sink_name                 = element(split("/", var.root_node), 0) == "organizations" ? "logs-audit-org-${local.parent_numeric_id}" : "logs-audit-folder-${local.parent_numeric_id}"
}

###############################################################################
#                        Shared resources folder                              #
###############################################################################

module "shared-folder" {
  source = "../modules/folders"
  parent = var.root_node
  names  = ["shared"]
}

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

# Terraform project

module "tf-project" {
  source              = "../../modules/project"
  name                = "terraform"
  parent              = module.shared-folder.id
  prefix              = var.prefix
  billing_account     = var.billing_account_id
  iam_nonauth_members = { "roles/owner" = var.iam_terraform_owners }
  iam_nonauth_roles   = ["roles/owner"]
  services            = var.project_services
}

# Bootstrap Terraform state GCS bucket

module "tf-gcs-bootstrap" {
  source     = "../../modules/gcs"
  project_id = module.tf-project.project_id
  names      = ["tf-bootstrap"]
  prefix     = "${var.prefix}-tf"
  location   = var.gcs_location
}

###############################################################################
#                              Business units                                 #
###############################################################################

# Business unit 1

module "business-unit-1-folders" {
  source            = "../modules/folders-unit"

  name              = var.business_unit_1_name
  automation_project_id = 
  billing_account_id = 
  gcs_defaults 
  iam_roles
  iam_members
  iam_enviroment_roles
  organization_id
  parent
  prefix
  environments      = var.environments
}

# Business unit 2

module "business-unit-2-folders" {
  source                    = "../modules/folders-unit"
  business_unit_folder_name = var.business_unit_2_name
  environments              = var.environments
  per_folder_admins         = module.service-accounts-tf-environments.iam_emails_list
  root_node                 = var.root_node

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

module "project-shared-resources" {
  source                 = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version                = "5.0.0"
  parent                 = module.shared-folder.id
  billing_account        = var.billing_account_id
  prefix                 = var.prefix
  name                   = "shared"
  lien_reason            = "shared"
  activate_apis          = var.project_services
  extra_bindings_roles   = var.shared_bindings_roles
  extra_bindings_members = var.shared_bindings_members
}

# Add further modules here for resources that are common to all business units
# like GCS buckets (used to hold shared assets), Container Registry, KMS, etc.
