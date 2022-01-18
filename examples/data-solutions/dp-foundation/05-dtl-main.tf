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

locals {
  group_iam_dtl = {
    "${local.groups.data-engineers}" = [
      "roles/bigquery.dataEditor",
      "roles/storage.admin",
      "roles/storage.objectCreator",
      "roles/storage.objectViewer",
      "roles/viewer",
    ],
    # "${local.groups.data-scientists}" = [
    #   "roles/bigquery.jobUser",
    # ]
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

###############################################################################
#                                 Project                                     #
###############################################################################

module "dtl-0-prj" {
  source          = "../../../modules/project"
  name            = "${var.project_id["datalake"]}-0"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
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
}

module "dtl-1-prj" {
  source          = "../../../modules/project"
  name            = "${var.project_id["datalake"]}-1"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
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
}

module "dtl-2-prj" {
  source          = "../../../modules/project"
  name            = "${var.project_id["datalake"]}-2"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
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
}

module "dtl-exp-prj" {
  source          = "../../../modules/project"
  name            = "${var.project_id["datalake"]}-exp"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
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
}
