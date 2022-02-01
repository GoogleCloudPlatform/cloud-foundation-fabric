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

# tfdoc:file:description Security project.

locals {
  group_iam_sec = {
    "${local.groups.data-engineers}" = [
      "roles/dlp.reader",
      "roles/dlp.user",
      "roles/dlp.estimatesAdmin",
    ],
    "${local.groups.data-security}" = [
      "roles/dlp.admin",
    ],
  }
  iam_sec = {
    "roles/dlp.user" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email
    ]
  }
  prefix_sec = "${var.prefix}-sec"
}

# Project

module "sec-prj" {
  source          = "../../../modules/project"
  name            = var.project_id["security"]
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_trf : {}
  iam_additive = var.project_create == null ? local.iam_trf : {}
  group_iam    = local.group_iam_trf
  services = concat(var.project_services, [
    "dlp.googleapis.com",
  ])
}

# Uncomment this section and assigne key links accondingly in local. variable
# if you want to create KMS keys in the security projet

# module "sec-kms-0" {
#   source     = "../../../modules/kms"
#   project_id = module.sec-prj.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-global",
#     location = var.location_config.region
#   }
#   keys = {
#     pubsub = null
#   }
# }

# module "sec-kms-1" {
#   source     = "../../../modules/kms"
#   project_id = module.sec-prj.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-mregional",
#     location = var.location_config.region
#   }
#   keys = {
#     bq      = null
#     storage = null
#   }
# }

# module "sec-kms-2" {
#   source     = "../../../modules/kms"
#   project_id = module.sec-prj.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-regional",
#     location = var.location_config.region
#   }
#   keys = {
#     composer = null
#     dataflow = null
#   }
# }
