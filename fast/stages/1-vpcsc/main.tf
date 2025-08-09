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
  discovered_projects = var.resource_discovery.enabled != true ? [] : [
    for v in module.vpc-sc-discovery[0].project_numbers :
    "projects/${v}"
  ]
  restricted_services = yamldecode(file(var.factories_config.restricted_services))
  # extend context with our own data
  context = {
    identity_sets = merge(var.context.identity_sets, {
      logging_identities = try(distinct(values(var.logging.writer_identities)), [])
    })
    project_numbers = try(var.project_numbers)
    resource_sets = merge(var.context.resource_sets, {
      discovered_projects = local.discovered_projects
      logging_project     = try(["projects/${var.logging.project_number}"], [])
    })
    service_sets = merge(var.context.service_sets, {
      restricted_services = local.restricted_services
    })
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
  context                 = local.context
  factories_config        = var.factories_config
  ingress_policies        = var.ingress_policies
  perimeters              = var.perimeters
  project_id_search_scope = "organizations/${var.organization.id}"
}
