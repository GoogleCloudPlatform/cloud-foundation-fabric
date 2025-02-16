/**
 * Copyright 2024 Google LLC
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
  _data = {
    for k, v in local._data_paths : k => {
      for f in try(fileset(v, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => yamldecode(file("${v}/${f}"))
    }
  }

  # Only perimeters are parsed here. Other factory configs are directly handled at VPC-SC module level
  _data_paths = {
    for k in ["perimeters"] : k => (
      var.factories_config[k] == null
      ? null
      : pathexpand(var.factories_config[k])
    )
  }

  _perimeter_filters = {
    for k, v in local._data.perimeters : k => try(v.resources_filter, "state:ACTIVE")
    if try(v.type != "bridge", true)
  }

  # Dynamically evaluate perimeter members if discovery is enabled
  dynamic_projects_map = {
    for k, v in local._perimeter_filters :
    k => (var.resource_discovery.enabled != true ? [] : [
      for p in module.vpc-sc-discovery[k].project_numbers :
      "projects/${p}"
      ]
    )
    if try(v.type != "bridge", true)
  }

  fast_ingress_policies = var.logging == null ? {} : {
    fast-org-log-sinks = {
      from = {
        access_levels = ["*"]
        identities    = values(var.logging.writer_identities)
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["projects/${var.logging.project_number}"]
      }
    }
  }
}

module "vpc-sc-discovery" {
  source           = "../../../modules/projects-data-source"
  for_each         = var.resource_discovery.enabled ? local._perimeter_filters : tomap({})
  parent           = coalesce(var.root_node, "organizations/${var.organization.id}")
  ignore_folders   = var.resource_discovery.ignore_folders
  ignore_projects  = var.resource_discovery.ignore_projects
  include_projects = var.resource_discovery.include_projects
  query            = each.value
}

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if the default perimeter is defined
  count         = length(local._data.perimeters) > 0 ? 1 : 0
  access_policy = var.access_policy
  access_policy_create = var.access_policy != null ? null : {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }

  dynamic_projects_map = local.dynamic_projects_map
  factories_config     = var.factories_config
  ingress_policies     = var.logging == null ? {} : local.fast_ingress_policies
}
