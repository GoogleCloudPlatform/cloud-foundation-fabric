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

# tfdoc:file:description common project.

locals {
  iam_common = {
    "roles/dlp.admin"          = [local.groups_iam.data-security]
    "roles/dlp.estimatesAdmin" = [local.groups_iam.data-engineers]
    "roles/dlp.reader"         = [local.groups_iam.data-engineers]
    "roles/dlp.user" = [
      module.load-sa-df-0.iam_email,
      module.transf-sa-df-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/datacatalog.admin" = [local.groups_iam.data-security]
    "roles/datacatalog.viewer" = [
      module.load-sa-df-0.iam_email,
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
      local.groups_iam.data-analysts
    ]
    "roles/datacatalog.categoryFineGrainedReader" = [
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
      # Uncomment if you want to grant access to `data-analyst` to all columns tagged.
      # local.groups_iam.data-analysts
    ]
  }
}
module "common-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.common : "${var.project_config.project_ids.common}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.iam_common : null
  iam_additive    = var.project_config.billing_account_id == null ? local.iam_common : null
  services = concat(var.project_services, [
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
  ])
}

# Data Catalog Policy tag

module "common-datacatalog" {
  source     = "../../../modules/data-catalog-policy-tag"
  project_id = module.common-project.project_id
  name       = "${var.prefix}-datacatalog-policy-tags"
  location   = var.location
  tags       = var.data_catalog_tags
}

# To create KMS keys in the common projet: uncomment this section and assigne key links accondingly in local.service_encryption_keys variable

# module "cmn-kms-0" {
#   source     = "../../../modules/kms"
#   project_id = module.common-project.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-global",
#     location = "global"
#   }
#   keys = {
#     pubsub = null
#   }
# }

# module "cmn-kms-1" {
#   source     = "../../../modules/kms"
#   project_id = module.common-project.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-mregional",
#     location = var.location
#   }
#   keys = {
#     bq      = null
#     storage = null
#   }
# }

# module "cmn-kms-2" {
#   source     = "../../../modules/kms"
#   project_id = module.cmn-prj.project_id
#   keyring = {
#     name     = "${var.prefix}-kr-regional",
#     location = var.region
#   }
#   keys = {
#     composer = null
#     dataflow = null
#   }
# }
