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
  billing_account_id = local.default_config.global.billing_account_id
  prefix             = local.default_config.global.projects.defaults.prefix
  iam_princial       = loca.default_config.context.iam_princials.gcp-organization-admins
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

resource "random_integer" "project_id_length" {
  min = 0
  max = 30 - length((local.prefix))
}

resource "random_string" "project_name" {
  length           = random_integer.project_id_length.result
  special          = false
  upper            = false
}

module "project" {
  source          = "../../../modules/project"
  billing_account = var.default_project_config.create ? local.billing_account_id : null
  name            = (var.default_project_config.create 
  && var.default_project_config.name == null ? 
  "${local.prefix}-${random_string.projec_name.result}" 
  : var.default_project_config.name)
  parent          = var.default_project_config.create ? local.parent : null
  prefix          = local.prefix
  project_reuse = {
    use_data_source = !var.default_project_config.create
  }
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
