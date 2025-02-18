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
  exp_tag = {
    key   = split("/", var.data_exposure_config.tag_name)[0]
    value = split("/", var.data_exposure_config.tag_name)[1]
  }
  folder_id = var.folder_ids[var.stage_config.name]
  prefix    = "${var.prefix}-${local.environment.short_name}"
  location  = lookup(var.regions, var.default_location, var.default_location)
}

module "central-project" {
  source                = "../../../modules/project"
  billing_account       = var.billing_account.id
  name                  = coalesce(var.central_project_config.name, "dp-central-0")
  parent                = var.folder_ids[var.stage_config.name]
  prefix                = local.prefix
  iam                   = var.central_project_config.iam
  iam_bindings          = var.central_project_config.iam_bindings
  iam_bindings_additive = var.central_project_config.iam_bindings_additive
  iam_by_principals     = var.central_project_config.iam_by_principals
  labels = {
    environment = var.stage_config.environment
  }
  services = var.central_project_config.services
  tags = merge(var.secure_tags, {
    (local.exp_tag.key) = {
      description = try(
        var.secure_tags[local.exp_tag.key].description,
        "Managed by the Terraform project module."
      )
      iam = try(var.secure_tags[local.exp_tag.key].description, {})
      values = merge(
        try(var.secure_tags[local.exp_tag.key].tags, {}),
        {
          (local.exp_tag.value) = {
            description = try(
              var.secure_tags[local.exp_tag.key].values[local.exp_tag.value].description,
              "Managed by the Terraform project module."
            )
            iam = try(
              var.secure_tags[local.exp_tag.key].values[local.exp_tag.value].iam,
              {}
            )
          }
        }
      )
    }
  })
}

module "central-tag-templates" {
  source     = "../../../modules/data-catalog-tag-template"
  project_id = module.central-project.project_id
  region     = local.region
  factories_config = {
    tag_templates = var.factories_config.policy_tags
    context = {
      regions = var.regions
    }
  }
}
