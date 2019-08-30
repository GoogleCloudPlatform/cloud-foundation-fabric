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
  version         = "3.2.0"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "terraform"
  lien_reason     = "terraform"
  owners          = var.terraform_owners
  activate_apis   = var.project_services
}

# Bootstrap Terraform state GCS bucket

module "gcs-tf-bootstrap" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "1.0.0"
  project_id = module.project-tf.project_id
  prefix     = "${var.prefix}-tf"
  names      = ["tf-bootstrap"]
  location   = var.gcs_location
}

###############################################################################
#                              Business units                                 #
###############################################################################

# Business unit 1

module "business-unit-1-folders-tree" {
  source = "./modules/business-unit-folders-tree"

  billing_account_id            = var.billing_account_id
  tf_project_id                 = module.project-tf.project_id
  top_level_folder_name         = var.business_unit_1_name
  second_level_folders_names    = var.business_unit_1_envs
  generate_service_account_keys = var.generate_service_account_keys
  gcs_location                  = var.gcs_location
  organization_id               = var.organization_id
  prefix                        = var.prefix
  root_node                     = var.root_node

}

# Business unit 2

module "business-unit-2-folders-tree" {
  source = "./modules/business-unit-folders-tree"

  billing_account_id            = var.billing_account_id
  tf_project_id                 = module.project-tf.project_id
  top_level_folder_name         = var.business_unit_2_name
  second_level_folders_names    = var.business_unit_2_envs
  generate_service_account_keys = var.generate_service_account_keys
  gcs_location                  = var.gcs_location
  organization_id               = var.organization_id
  prefix                        = var.prefix
  root_node                     = var.root_node

}

# Business unit 3

module "business-unit-3-folders-tree" {
  source = "./modules/business-unit-folders-tree"

  billing_account_id            = var.billing_account_id
  tf_project_id                 = module.project-tf.project_id
  top_level_folder_name         = var.business_unit_3_name
  second_level_folders_names    = var.business_unit_3_envs
  generate_service_account_keys = var.generate_service_account_keys
  gcs_location                  = var.gcs_location
  organization_id               = var.organization_id
  prefix                        = var.prefix
  root_node                     = var.root_node

}

###############################################################################
#                              Audit log exports                              #
###############################################################################

# Audit logs project

module "project-audit" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.2.0"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "audit"
  lien_reason     = "audit"
  activate_apis   = var.project_services
  viewers         = var.audit_viewers
}

# Audit logs destination on BigQuery

module "bq-audit-export" {
  source                   = "terraform-google-modules/log-export/google//modules/bigquery"
  version                  = "3.0.0"
  project_id               = module.project-audit.project_id
  dataset_name             = "logs_audit_${replace(var.business_unit_1_name, "-", "_")}"
  log_sink_writer_identity = module.log-sink-audit.writer_identity
}

# Audit log sink for business unit 1
# set the organization as parent to export audit logs for all business units

module "log-sink-audit" {
  source                 = "terraform-google-modules/log-export/google"
  version                = "3.0.0"
  filter                 = "logName: \"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName: \"/logs/cloudaudit.googleapis.com%2Fsystem_event\""
  log_sink_name          = "logs-audit-${var.business_unit_1_name}"
  parent_resource_type   = "folder"
  parent_resource_id     = split("/", module.business-unit-1-folders-tree.top_level_folder_id)[1]
  include_children       = "true"
  unique_writer_identity = "true"
  destination_uri        = "${module.bq-audit-export.destination_uri}"
}

###############################################################################
#                    Shared resources (GCR, GCS, KMS, etc.)                   #
###############################################################################

# Shared resources project

module "project-shared-resources" {
  source                 = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version                = "3.2.0"
  parent                 = var.root_node
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
