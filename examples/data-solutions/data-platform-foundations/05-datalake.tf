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

# tfdoc:file:description Datalake projects.

locals {
  lake_group_iam = {
    (local.groups.data-engineers) = [
      "roles/bigquery.dataEditor",
      "roles/storage.admin",
    ],
    (local.groups.data-analysts) = [
      "roles/bigquery.dataViewer",
      "roles/bigquery.jobUser",
      "roles/bigquery.user",
      "roles/datacatalog.viewer",
      "roles/datacatalog.tagTemplateViewer",
      "roles/storage.objectViewer",
    ]
  }
  lake_plg_group_iam = {
    (local.groups.data-engineers) = [
      "roles/bigquery.dataEditor",
      "roles/storage.admin",
    ],
    (local.groups.data-analysts) = [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/bigquery.user",
      "roles/datacatalog.viewer",
      "roles/datacatalog.tagTemplateViewer",
      "roles/storage.objectAdmin",
    ]
  }
  lake_0_iam = {
    "roles/bigquery.dataEditor" = [
      module.load-sa-df-0.iam_email,
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.load-sa-df-0.iam_email,
    ]
    "roles/storage.objectCreator" = [
      module.load-sa-df-0.iam_email,
    ]
  }
  lake_iam = {
    "roles/bigquery.dataEditor" = [
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/storage.objectCreator" = [
      module.transf-sa-df-0.iam_email,
    ]
    "roles/storage.objectViewer" = [
      module.transf-sa-df-0.iam_email,
    ]
  }
  lake_services = concat(var.project_services, [
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

module "lake-0-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "dtl-0${local.project_suffix}"
  group_iam       = local.lake_group_iam
  iam             = local.lake_0_iam
  services        = local.lake_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "lake-1-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "dtl-1${local.project_suffix}"
  group_iam       = local.lake_group_iam
  iam             = local.lake_iam
  services        = local.lake_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "lake-2-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "dtl-2${local.project_suffix}"
  group_iam       = local.lake_group_iam
  iam             = local.lake_iam
  services        = local.lake_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "lake-plg-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "dtl-plg${local.project_suffix}"
  group_iam       = local.lake_plg_group_iam
  iam             = {}
  services        = local.lake_services
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

# Bigquery

module "lake-0-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.lake-0-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dtl_0_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

module "lake-1-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.lake-1-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dtl_1_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

module "lake-2-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.lake-2-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dtl_2_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

module "lake-plg-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.lake-plg-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_dtl_plg_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}

# Cloud storage

module "lake-0-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.lake-0-project.project_id
  prefix         = var.prefix
  name           = "dtl-0-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

module "lake-1-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.lake-1-project.project_id
  prefix         = var.prefix
  name           = "dtl-1-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

module "lake-2-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.lake-2-project.project_id
  prefix         = var.prefix
  name           = "dtl-2-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

module "lake-plg-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.lake-plg-project.project_id
  prefix         = var.prefix
  name           = "dtl-plg-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}
