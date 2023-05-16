# Copyright 2022 Google LLC
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

# tfdoc:file:description Data curated project and resources.

locals {
  cur_iam = {
    "roles/bigquery.dataOwner" = [module.processing-sa-0.iam_email]
    "roles/bigquery.dataViewer" = [
      local.groups_iam.data-analysts,
      local.groups_iam.data-engineers
    ]
    "roles/bigquery.jobUser" = [
      module.processing-sa-0.iam_email,
      local.groups_iam.data-analysts,
      local.groups_iam.data-engineers
    ]
    "roles/datacatalog.tagTemplateViewer" = [
      local.groups_iam.data-analysts, local.groups_iam.data-engineers
    ]
    "roles/datacatalog.viewer" = [
      local.groups_iam.data-analysts, local.groups_iam.data-engineers
    ]
    "roles/storage.objectViewer" = [
      local.groups_iam.data-analysts, local.groups_iam.data-engineers
    ]
    "roles/storage.objectAdmin" = [module.processing-sa-0.iam_email]
  }
  cur_services = [
    "iam.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ]
}

# Project

module "cur-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.curated
    : "${var.project_config.project_ids.curated}${local.project_suffix}"
  )
  iam          = var.project_config.billing_account_id != null ? local.cur_iam : {}
  iam_additive = var.project_config.billing_account_id == null ? local.cur_iam : {}
  services     = local.cur_services
  service_encryption_key_ids = {
    bq      = [var.service_encryption_keys.bq]
    storage = [var.service_encryption_keys.storage]
  }
}

# Bigquery

module "cur-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.cur-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_cur_bq_0"
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
}

# Cloud storage

module "cur-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.cur-project.project_id
  prefix         = var.prefix
  name           = "cur-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = var.data_force_destroy
}
