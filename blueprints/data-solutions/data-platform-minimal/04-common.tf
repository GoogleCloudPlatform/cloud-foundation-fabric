# Copyright 2024 Google LLC
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

# tfdoc:file:description Common project and resources.

locals {
  iam_cmn = {
    "roles/dlp.admin" = [
      local.groups_iam.data-security
    ]
    "roles/dlp.estimatesAdmin" = [
      local.groups_iam.data-engineers
    ]
    "roles/dlp.reader" = [
      local.groups_iam.data-engineers
    ]
    "roles/dlp.user" = [
      module.processing-sa-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/datacatalog.admin" = [
      local.groups_iam.data-security
    ]
    "roles/datacatalog.viewer" = [
      module.processing-sa-0.iam_email,
      local.groups_iam.data-analysts
    ]
    "roles/datacatalog.categoryFineGrainedReader" = [
      module.processing-sa-0.iam_email
    ]
    "roles/dlp.serviceAgent" = [
      module.common-project.service_agents.dlp-api.iam_email
    ]
  }
  # this only works because the service account module uses a static output
  iam_cmn_additive = {
    for k in flatten([
      for role, members in local.iam_cmn : [
        for member in members : {
          role   = role
          member = member
        }
      ]
    ]) : "${k.member}-${k.role}" => k
  }
}
module "common-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.common
    : "${var.project_config.project_ids.common}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id == null ? {} : local.iam_cmn
  )
  iam_bindings_additive = (
    var.project_config.billing_account_id != null ? {} : local.iam_cmn_additive
  )
  services = [
    "cloudresourcemanager.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}

# Data Catalog Policy tag

module "common-datacatalog" {
  source     = "../../../modules/data-catalog-policy-tag"
  project_id = module.common-project.project_id
  name       = "${var.prefix}-datacatalog-policy-tags"
  location   = var.location
  tags       = var.data_catalog_tags
}
