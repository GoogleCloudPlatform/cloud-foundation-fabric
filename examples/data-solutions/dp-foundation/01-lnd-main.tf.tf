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
  group_iam_lnd = {
    "${local.groups.data-engineers}" = [
      "roles/bigquery.dataEditor",
      "roles/pubsub.editor",
      "roles/storage.admin",
      "roles/storage.objectViewer",
      "roles/viewer",
    ],
    # "${local.groups.data-scientists}" = [
    #   "roles/bigquery.dataViewer",
    #   "roles/bigquery.jobUser",
    #   "roles/bigquery.user",
    #   "roles/pubsub.viewer",
    # ]
  }
  iam_lnd = {
    "roles/bigquery.dataEditor" = [
      module.lnd-sa-bq-0.iam_email,
    ]
    "roles/bigquery.dataViewer" = [
      module.lod-sa-df-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.orc-sa-cmp-0.iam_email
    ]
    "roles/bigquery.user" = [
      module.lod-sa-df-0.iam_email
    ]
    "roles/pubsub.publisher" = [
      module.lnd-sa-ps-0.iam_email
    ]
    "roles/pubsub.subscriber" = [
      module.lod-sa-df-0.iam_email,
      module.orc-sa-cmp-0.iam_email
    ]
    "roles/storage.objectAdmin" = [
      module.lod-sa-df-0.iam_email,
    ]
    "roles/storage.objectCreator" = [
      module.lnd-sa-cs-0.iam_email,
    ]
    "roles/storage.objectViewer" = [
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/storage.admin" = [
      module.lod-sa-df-0.iam_email,
    ]
  }
  prefix_lnd = "${var.prefix}-lnd"
}

###############################################################################
#                                 Project                                     #
###############################################################################

module "lnd-prj" {
  source          = "../../../modules/project"
  name            = var.project_id["landing"]
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_lnd : {}
  iam_additive = var.project_create == null ? local.iam_lnd : {}
  # group_iam    = local.group_iam_lnd
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ])
}
