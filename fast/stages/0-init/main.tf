/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  default_config     = yamldecode(file("${path.module}/../0-org-setup/${var.defaults_factory_config}"))
  organization_id    = local.default_config.global.organization.id
  parent             = "organizations/${local.organization_id}"
  billing_account_id = local.default_config.global.billing_account
  prefix             = local.default_config.projects.defaults.prefix
  iam_princial       = local.default_config.context.iam_principals.gcp-organization-admins
  active_org_policies = [
    for x in data.google_cloud_asset_search_all_resources.policies.results :
    x.display_name
    if x.parent_asset_type == "cloudresourcemanager.googleapis.com/Organization"
  ]
}

output "yaml" {
  value = local.default_config.projects.defaults.prefix
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = local.parent
  iam_by_principals_additive = {
    (local.iam_princial) = [
      "roles/billing.admin",
      "roles/logging.admin",
      "roles/iam.organizationRoleAdmin",
      "roles/orgpolicy.policyAdmin",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.organizationAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/resourcemanager.tagAdmin",
      "roles/owner"
    ]
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

module "project" {
  source          = "../../../modules/project"
  billing_account = var.default_project_config.create ? local.billing_account_id : null
  name = coalesce(
    var.default_project_config.id,
    "${local.prefix}-init-${random_string.suffix.result}"
  )
  parent = var.default_project_config.create ? local.parent : null
  prefix = local.prefix
  # project_reuse = !var.default_project_config.create ? null : {
  #   use_data_source = !var.default_project_config.create
  # }
  services = [
    "bigquery.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "essentialcontacts.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "orgpolicy.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

data "google_cloud_asset_search_all_resources" "policies" {
  scope = local.parent
  asset_types = [
    "orgpolicy.googleapis.com/Policy"
  ]
}
