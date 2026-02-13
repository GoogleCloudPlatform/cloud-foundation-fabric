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

locals {
  _ctx = {
    for k, v in var.context : k => merge(
      v, try(local._defaults.context[k], {})
    )
  }
  # dereferencing for outputs bucket
  _ctx_buckets = {
    for k, v in local.ctx.storage_buckets : "$storage_buckets:${k}" => v
  }
  # fail if we have no valid defaults
  _defaults = yamldecode(file(local.paths.defaults))
  discovered_projects = var.resource_discovery.enabled != true ? [] : [
    for v in module.vpc-sc-discovery[0].project_numbers :
    "projects/${v}"
  ]
  restricted_services = yamldecode(file(local.paths.restricted_services))
  # extend context with our own data
  ctx = merge(local._ctx, {
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        "service_accounts/${k}" => "serviceAccount:${v}"
      },
      local._ctx.iam_principals
    )
    identity_sets = merge(local._ctx.identity_sets, {
      logging_identities = try(distinct(values(var.logging.writer_identities)), [])
    })
    project_numbers = merge(var.project_numbers, local._ctx.project_numbers)
    resource_sets = merge(
      {
        discovered_projects = local.discovered_projects
        logging_project     = try(["projects/${var.logging.project_number}"], [])
        org_setup_projects = [
          for k, v in var.project_numbers : "projects/${v}"
        ]
      },
      local._ctx.resource_sets
    )
    service_sets = merge(
      {
        restricted_services = local.restricted_services
      },
      local._ctx.service_sets
    )
    storage_buckets = merge(var.storage_buckets, local._ctx.storage_buckets)
  })
  # normalize defaults (only used for output files here)
  defaults = {
    stage_name = try(local._defaults.global.stage_name, "1-vpcsc")
  }
  output_files = {
    local_path = try(local._defaults.output_files.local_path, null)
    storage_bucket = try(
      local._ctx_buckets[local._defaults.output_files.storage_bucket],
      local._defaults.output_files.storage_bucket,
      null
    )
  }
  paths = {
    for k, v in var.factories_config.paths : k => try(pathexpand(
      startswith(v, "/") || startswith(v, ".")
      ? v :
      "${var.factories_config.dataset}/${v}"
    ), null)
  }
}

module "vpc-sc-discovery" {
  source           = "../../../modules/projects-data-source"
  count            = var.resource_discovery.enabled == true ? 1 : 0
  parent           = coalesce(var.root_node, "organizations/${var.organization.id}")
  ignore_folders   = var.resource_discovery.ignore_folders
  ignore_projects  = var.resource_discovery.ignore_projects
  include_projects = var.resource_discovery.include_projects
  query            = "state:ACTIVE"
}

module "vpc-sc" {
  source        = "../../../modules/vpc-sc"
  access_policy = var.access_policy
  access_policy_create = var.access_policy != null ? null : {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }
  access_levels           = var.access_levels
  egress_policies         = var.egress_policies
  context                 = local.ctx
  factories_config        = local.paths
  ingress_policies        = var.ingress_policies
  perimeters              = var.perimeters
  project_id_search_scope = "organizations/${var.organization.id}"
}
