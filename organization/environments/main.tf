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
  # source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  # version         = "3.0.1"
  source          = "github.com/terraform-google-modules/terraform-google-project-factory//modules/fabric-project?ref=32a539a"
  parent_type     = var.root_type
  parent_id       = var.org_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "terraform"
  lien_reason     = "terraform"
  owners          = var.terraform_owners
  activate_apis   = var.project_services
}

# per-environment service accounts

module "service-accounts-tf-environments" {
  # source             = "terraform-google-modules/service-accounts/google"
  # version            = "1.0.1"
  source             = "github.com/terraform-google-modules/terraform-google-service-accounts?ref=857f394"
  project_id         = module.project-tf.project_id
  org_id             = var.org_id
  billing_account_id = var.billing_account_id
  prefix             = var.prefix
  names              = var.environments
  grant_billing_role = true
  grant_xpn_roles    = true
  generate_keys      = true
}

# bootstrap Terraform state  GCS bucket

module "gcs-tf-bootstrap" {
  # source        = "terraform-google-modules/cloud-storage/google"
  # version       = "1.0.0"
  source     = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=e7243fd"
  project_id = module.project-tf.project_id
  prefix     = "${var.prefix}-tf"
  names      = ["tf-bootstrap"]
  location   = var.gcs_location
}

# per-environment Terraform state GCS buckets

module "gcs-tf-environments" {
  # source        = "terraform-google-modules/cloud-storage/google"
  # version       = "1.0.0"
  source          = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=e7243fd"
  project_id      = module.project-tf.project_id
  prefix          = "${var.prefix}-tf"
  names           = var.environments
  location        = var.gcs_location
  set_admin_roles = true
  bucket_admins = zipmap(
    var.environments,
    module.service-accounts-tf-environments.iam_emails
  )
}

###############################################################################
#                              Top-level folders                              #
###############################################################################

# TODO(ludomagno): move XPN admin role here after checking it now works on folders

module "folders-top-level" {
  source            = "terraform-google-modules/folders/google"
  version           = "1.0.0"
  parent_type       = var.root_type
  parent_id         = var.org_id
  names             = var.environments
  set_roles         = true
  per_folder_admins = module.service-accounts-tf-environments.iam_emails
  folder_admin_roles = [
    "roles/resourcemanager.folderViewer",
    "roles/resourcemanager.projectCreator",
    "roles/owner",
    "roles/compute.networkAdmin",
  ]
}

###############################################################################
#                              Audit log exports                              #
###############################################################################

# Audit logs project

module "project-audit" {
  # source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  # version         = "3.0.1"
  source          = "github.com/terraform-google-modules/terraform-google-project-factory//modules/fabric-project?ref=32a539a"
  parent_type     = var.root_type
  parent_id       = var.org_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "audit"
  lien_reason     = "audit"
  activate_apis   = var.project_services
}

# audit logs destination on BigQuery

module "bq-audit-export" {
  source                   = "terraform-google-modules/log-export/google//modules/bigquery"
  version                  = "3.0.0"
  project_id               = module.project-audit.project_id
  dataset_name             = "logs_audit_${replace(var.environments[0], "-", "_")}"
  log_sink_writer_identity = module.log-sink-audit.writer_identity
}

# This sink exports  audit logs for the first environment only, change the
# parent resource to the organization to have organization-wide audit exports

module "log-sink-audit" {
  source                 = "terraform-google-modules/log-export/google"
  version                = "3.0.0"
  filter                 = "logName: \"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName: \"/logs/cloudaudit.googleapis.com%2Fsystem_event\""
  log_sink_name          = "logs-audit-${var.environments[0]}"
  parent_resource_type   = "folder"
  parent_resource_id     = "${element(values(module.folders-top-level.names_and_ids), 0)}"
  include_children       = "true"
  unique_writer_identity = "true"
  destination_uri        = "${module.bq-audit-export.destination_uri}"
}

###############################################################################
#                    Shared resources (GCR, GCS, KMS, etc.)                   #
###############################################################################

# Shared resources project

module "project-shared-resources" {
  # source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  # version         = "3.0.1"
  source          = "github.com/terraform-google-modules/terraform-google-project-factory//modules/fabric-project?ref=32a539a"
  parent_type     = var.root_type
  parent_id       = var.org_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "shared"
  lien_reason     = "shared"
  activate_apis   = var.project_services
}

# Add here further modules for resources that don't belong to any environments,
# like GCS buckets to hold assets, KMS, etc.
