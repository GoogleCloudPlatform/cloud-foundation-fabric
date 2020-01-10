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

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

# Terraform project

module "project-tf" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "5.0.0"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "terraform"
  lien_reason     = "terraform"
  owners          = var.terraform_owners
  activate_apis   = var.project_services
}

# per-environment service accounts

module "service-accounts-tf-environments" {
  source             = "terraform-google-modules/service-accounts/google"
  version            = "2.0.2"
  project_id         = module.project-tf.project_id
  org_id             = var.organization_id
  billing_account_id = var.billing_account_id
  prefix             = var.prefix
  names              = var.environments
  grant_billing_role = true
  grant_xpn_roles    = var.grant_xpn_org_roles
  generate_keys      = var.generate_service_account_keys
}

# bootstrap Terraform state GCS bucket

module "gcs-tf-bootstrap" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "1.0.0"
  project_id = module.project-tf.project_id
  prefix     = "${var.prefix}-tf"
  names      = ["tf-bootstrap"]
  location   = var.gcs_location
}

# per-environment Terraform state GCS buckets

module "gcs-tf-environments" {
  source          = "terraform-google-modules/cloud-storage/google"
  version         = "1.0.0"
  project_id      = module.project-tf.project_id
  prefix          = "${var.prefix}-tf"
  names           = var.environments
  location        = var.gcs_location
  set_admin_roles = true
  bucket_admins = zipmap(
    var.environments,
    module.service-accounts-tf-environments.iam_emails_list
  )
}

###############################################################################
#                              Top-level folders                              #
###############################################################################

module "folders-top-level" {
  source            = "terraform-google-modules/folders/google"
  version           = "2.0.2"
  parent            = var.root_node
  names             = var.environments
  set_roles         = true
  per_folder_admins = module.service-accounts-tf-environments.iam_emails_list
  folder_admin_roles = compact(
    [
      "roles/compute.networkAdmin",
      "roles/owner",
      "roles/resourcemanager.folderViewer",
      "roles/resourcemanager.projectCreator",
      var.grant_xpn_folder_roles ? "roles/compute.xpnAdmin" : ""
    ]
  )
}

###############################################################################
#                              Audit log exports                              #
###############################################################################

# audit logs project

module "project-audit" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "5.0.0"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "audit"
  lien_reason     = "audit"
  activate_apis = concat(var.project_services, [
    "bigquery.googleapis.com",
  ])
  viewers = var.audit_viewers
}

# audit logs destination on BigQuery

module "bq-audit-export" {
  source                   = "terraform-google-modules/log-export/google//modules/bigquery"
  version                  = "3.2.0"
  project_id               = module.project-audit.project_id
  dataset_name             = "logs_audit_${replace(var.environments[0], "-", "_")}"
  log_sink_writer_identity = module.log-sink-audit.writer_identity
}

# audit log sink
# set the organization as parent to export audit logs for all environments

module "log-sink-audit" {
  source                 = "terraform-google-modules/log-export/google"
  version                = "3.2.0"
  filter                 = var.audit_filter
  log_sink_name          = "logs-audit-${var.environments[0]}"
  parent_resource_type   = "folder"
  parent_resource_id     = split("/", module.folders-top-level.ids_list[0])[1]
  include_children       = "true"
  unique_writer_identity = "true"
  destination_uri        = "${module.bq-audit-export.destination_uri}"
}

###############################################################################
#                    Shared resources (GCR, GCS, KMS, etc.)                   #
###############################################################################

# shared resources project
# see the README file for additional options on managing shared services

module "project-shared-resources" {
  source                 = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version                = "5.0.0"
  parent                 = var.root_node
  billing_account        = var.billing_account_id
  prefix                 = var.prefix
  name                   = "shared"
  lien_reason            = "shared"
  activate_apis          = var.project_services
  extra_bindings_roles   = var.shared_bindings_roles
  extra_bindings_members = var.shared_bindings_members
}

# Add further modules here for resources that are common to all environments
# like GCS buckets (used to hold shared assets), Container Registry, KMS, etc.
