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
  group_iam_dtl = {
    "${local.groups.data-engineers}" = [
      "roles/bigquery.dataEditor",
      "roles/storage.admin",
    ],
    "${local.groups.data-analysts}" = [
      "roles/bigquery.dataViewer",
      "roles/bigquery.jobUser",
      "roles/bigquery.user",
      "roles/datacatalog.viewer",
      "roles/datacatalog.tagTemplateViewer",
      "roles/storage.objectViewer",
    ]
  }
  iam_dtl = {
    "roles/bigquery.dataEditor" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
      module.trf-sa-bq-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
    ]
    "roles/storage.admin" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
    ]
    "roles/storage.objectCreator" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
      module.trf-sa-bq-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/storage.objectViewer" = [
      module.trf-sa-df-0.iam_email,
      module.trf-sa-bq-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
  }
  prefix_dtl = "${var.prefix}-dtl"
}

# Project

module "dtl-0-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["datalake-l0"], "dtl-0")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["datalake-l0"])
  prefix          = can(var.project_ids["datalake-l0"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_dtl : {}
  iam_additive = var.project_create == null ? local.iam_dtl : {}
  group_iam    = local.group_iam_dtl
  services = concat(var.project_services, [
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
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "dtl-1-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["datalake-l1"], "dtl-1")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["datalake-l1"])
  prefix          = can(var.project_ids["datalake-l1"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_dtl : {}
  iam_additive = var.project_create == null ? local.iam_dtl : {}
  group_iam    = local.group_iam_dtl
  services = concat(var.project_services, [
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
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "dtl-2-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["datalake-l2"], "dtl-2")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["datalake-l2"])
  prefix          = can(var.project_ids["datalake-l2"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_dtl : {}
  iam_additive = var.project_create == null ? local.iam_dtl : {}
  group_iam    = local.group_iam_dtl
  services = concat(var.project_services, [
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
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

module "dtl-plg-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["datalake-playground"], "dtl-plg")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["datalake-playground"])
  prefix          = can(var.project_ids["datalake-playground"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_dtl : {}
  iam_additive = var.project_create == null ? local.iam_dtl : {}
  group_iam    = local.group_iam_dtl
  services = concat(var.project_services, [
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
  service_encryption_key_ids = {
    bq      = [try(local.service_encryption_keys.bq, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}
