/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Data platform project-factory approach.

# use project factory to create hierarchy, projects, buckets and service accounts
locals {
  environment = var.environments[var.config.environment]
  exp_tag = {
    key   = split("/", var.exposure_config.tag_name)[0]
    value = split("/", var.exposure_config.tag_name)[1]
  }
  folder_id = var.folder_ids[var.config.name]
  location  = lookup(var.regions, var.location, var.location)
  prefix = (
    "${var.prefix}-${local.environment.short_name}-${var.config.short_name}"
  )
  prefix_bq = replace(local.prefix, "-", "_")
}

module "central-project" {
  source                = "../../../modules/project"
  billing_account       = var.billing_account.id
  name                  = var.central_project_config.short_name
  parent                = var.folder_ids[var.config.name]
  prefix                = local.prefix
  iam                   = var.central_project_config.iam
  iam_bindings          = var.central_project_config.iam_bindings
  iam_bindings_additive = var.central_project_config.iam_bindings_additive
  iam_by_principals     = var.central_project_config.iam_by_principals
  labels = {
    environment = var.config.environment
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
  region     = local.location
  factories_config = {
    tag_templates = var.factories_config.tag_templates
    context = {
      regions = var.regions
    }
  }
}

module "central-policy-tags" {
  source     = "../../../modules/data-catalog-policy-tag"
  project_id = module.central-project.project_id
  name       = "tags"
  location   = var.location
  #TODO Add factory support and remove hardcoded tags
  tags = {
    low    = {}
    medium = {}
    high   = {}
  }
}

module "projects" {
  source = "../../../modules/project-factory"
  data_defaults = {
    # more defaults are available, check the project factory variables
    billing_account  = var.billing_account.id
    storage_location = var.locations.gcs
  }
  data_merges = {
    services = [
      "stackdriver.googleapis.com"
    ]
  }
  data_overrides = {
    prefix = var.prefix
  }
  factories_config = merge(var.factories_config, {
    context = {
      folder_ids = merge(
        { for k, v in var.folder_ids : k => v if v != null },
        var.factories_config.context.folder_ids
      )
      iam_principals = merge(
        # {
        #   for k, v in var.service_accounts :
        #   k => "serviceAccount:${v}" if v != null
        # },
        # var.groups,
        var.factories_config.context.iam_principals
      )
      tag_values = merge(
        # var.tag_values,
        var.factories_config.context.tag_values
      )
      vpc_host_projects = merge(
        var.host_project_ids,
        var.factories_config.context.vpc_host_projects
      )
    }
    },
    {
      folders_data_path  = var.factories_config.data_domains
      projects_data_path = var.factories_config.data_domains
    }
  )
}

module "dp-buckets" {
  source = "../../../modules/gcs"
  for_each = {
    for v in local.dp_buckets : "${v.dp}/${v.key}" => v
  }
  project_id = module.dp-projects[each.value.dp].project_id
  prefix     = local.prefix
  name       = "${each.value.dps}-${each.value.short_name}-0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central-project.tag_values["${var.exposure_config.tag_name}"].id
    )
  }
}

module "dp-datasets" {
  source = "../../../modules/bigquery-dataset"
  for_each = {
    for v in local.dp_datasets : "${v.dp}/${v.key}" => v
  }
  project_id = module.projects[each.value.dp].project_id
  id         = "${local.prefix_bq}_${each.value.dps}_${each.value.short_name}_0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central-project.tag_values["${var.exposure_config.tag_name}"].id
    )
  }
}
