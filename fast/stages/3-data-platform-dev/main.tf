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
    key   = split("/", var.exposure_config.tag_name)[0]
    value = split("/", var.exposure_config.tag_name)[1]
  }
  kms_keys = merge(
    var.kms_keys, var.factories_config.context.kms_keys
  )
  location = lookup(var.regions, var.location, var.location)
  prefix = (
    "${var.prefix}-${local.environment.short_name}-${var.stage_config.short_name}"
  )
  prefix_bq = replace(local.prefix, "-", "_")
  tag_values = merge(
    var.tag_values,
    var.factories_config.context.tag_values,
    { for k, v in module.central-project.tag_values : k => v.id }
  )
}

module "central-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = var.central_project_config.short_name
  parent          = var.folder_ids[var.stage_config.name]
  prefix          = local.prefix
  iam = {
    for k, v in var.central_project_config.iam : k => [
      for m in v : lookup(
        var.factories_config.context.iam_principals, m, m
      )
    ]
  }
  iam_bindings = {
    for k, v in var.central_project_config.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : lookup(
          var.factories_config.context.iam_principals, m, m
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in var.central_project_config.iam_bindings_additive : k => merge(v, {
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_by_principals = {
    for k, v in var.central_project_config.iam_by_principals :
    lookup(var.factories_config.context.iam_principals, k, k) => v
  }
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
      iam = {
        for k, v in try(var.secure_tags[local.exp_tag.key].iam, {}) :
        k => [
          for m in v : lookup(
            var.factories_config.context.iam_principals, m, m
          )
        ]
      }
      values = merge(
        try(var.secure_tags[local.exp_tag.key].values, {}),
        {
          (local.exp_tag.value) = {
            description = try(
              var.secure_tags[local.exp_tag.key].values[local.exp_tag.value].description,
              "Managed by the Terraform project module."
            )
            iam = {
              for k, v in try(var.secure_tags[local.exp_tag.key].values[local.exp_tag.value].iam, {}) :
              k => [
                for m in v : lookup(
                  var.factories_config.context.iam_principals, m, m
                )
              ]
            }
          }
        }
      )
    }
  })
}

module "central-aspect-types" {
  source     = "../../../modules/dataplex-aspect-types"
  project_id = module.central-project.project_id
  location   = local.location
  factories_config = {
    aspect_types = var.factories_config.aspect_types
  }
  aspect_types = var.aspect_types
}

# TODO: Migrate to new Policy Tag on BQ.
module "central-policy-tags" {
  source     = "../../../modules/data-catalog-policy-tag"
  project_id = module.central-project.project_id
  name       = "tags"
  location   = var.location
  tags       = var.central_project_config.policy_tags
}
