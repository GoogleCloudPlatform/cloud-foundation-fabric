/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Locals and project-level resources.

locals {
  environment = var.environments[var.stage_config.environment]
  folder_id   = var.folder_ids[var.stage_config.name]
  prefix      = "${var.prefix}-${local.environment.short_name}"
  region      = lookup(var.regions, var.default_region, var.default_region)
}

module "shared-project" {
  source                = "../../../modules/project"
  billing_account       = var.billing_account.id
  name                  = coalesce(var.shared_project_config.name, "dp-shared-0")
  parent                = var.folder_ids[var.stage_config.name]
  prefix                = local.prefix
  iam                   = var.shared_project_config.iam
  iam_bindings          = var.shared_project_config.iam_bindings
  iam_bindings_additive = var.shared_project_config.iam_bindings_additive
  iam_by_principals     = var.shared_project_config.iam_by_principals
  labels = {
    environment = var.stage_config.environment
  }
  services = var.shared_project_config.services
}

module "shared-tag-templates" {
  source     = "../../../modules/data-catalog-tag-template"
  project_id = module.shared-project.project_id
  region     = local.region
  factories_config = {
    tag_templates = var.factories_config.policy_tags
  }
}
