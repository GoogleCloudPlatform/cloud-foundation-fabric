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

# tfdoc:file:description Data Warehouse projects.

locals {
  dwh_lnd_iam = {
    "roles/bigquery.dataOwner" = [
      module.load-sa-df-0.iam_email,
    ]
    "roles/bigquery.dataViewer" = [
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/bigquery.jobUser" = [
      module.load-sa-df-0.iam_email, local.groups_iam.data-engineers
    ]
    "roles/datacatalog.categoryAdmin"     = [module.transf-sa-bq-0.iam_email]
    "roles/datacatalog.tagTemplateViewer" = [local.groups_iam.data-engineers]
    "roles/datacatalog.viewer"            = [local.groups_iam.data-engineers]
    "roles/storage.objectCreator"         = [module.load-sa-df-0.iam_email]
    "roles/storage.objectViewer"          = [local.groups_iam.data-engineers]
  }
  dwh_iam = {
    "roles/bigquery.dataOwner" = [
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/bigquery.dataViewer" = [
      local.groups_iam.data-analysts,
      local.groups_iam.data-engineers
    ]
    "roles/bigquery.jobUser" = [
      module.transf-sa-bq-0.iam_email,
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
    "roles/storage.objectAdmin" = [module.transf-sa-df-0.iam_email]
  }
  dwh_services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
}

# Project

module "dwh-lnd-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.dwh-lnd : "${var.project_config.project_ids.dwh-lnd}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.dwh_lnd_iam : {}
  iam_additive    = var.project_config.billing_account_id == null ? local.dwh_lnd_iam : {}
  services        = local.dwh_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "dwh-cur-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.dwh-cur : "${var.project_config.project_ids.dwh-cur}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.dwh_iam : {}
  iam_additive    = var.project_config.billing_account_id == null ? local.dwh_iam : {}
  services        = local.dwh_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "dwh-conf-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.dwh-conf : "${var.project_config.project_ids.dwh-conf}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.dwh_iam : null
  iam_additive    = var.project_config.billing_account_id == null ? local.dwh_iam : null
  services        = local.dwh_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

# Bigquery

module "dwh-lnd-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dwh-lnd-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dwh_lnd_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

module "dwh-cur-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dwh-cur-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dwh_cur_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

module "dwh-conf-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dwh-conf-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dwh_conf_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

# Cloud storage

module "dwh-lnd-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dwh-lnd-project.project_id
  prefix         = var.prefix
  name           = "dwh-lnd-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

module "dwh-cur-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dwh-cur-project.project_id
  prefix         = var.prefix
  name           = "dwh-cur-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

module "dwh-conf-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dwh-conf-project.project_id
  prefix         = var.prefix
  name           = "dwh-conf-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}
