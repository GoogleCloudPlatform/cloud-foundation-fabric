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

  # Default perimeter configuration if not defined in tfvars or factory
  _perimeter_default = {
    default = {
      access_levels    = ["geo"]
      dry_run          = true
      egress_policies  = []
      ingress_policies = ["fast-org-log-sinks"]
      resources        = []
      type             = "regular"
    }
  }

  _perimeters = merge(var.perimeters,
    local._data.perimeters,
  length(local._perimeters_names) < 1 ? local._perimeter_default : null)

  # Dynamically evaluate perimeter members if discovery is enabledd
  _perimeters_projects = {
    for k, v in local._perimeters :
    k => distinct(concat(
      v.resources,
      var.resource_discovery.enabled != true ? [] : [
        for p in module.vpc-sc-discovery[k].project_numbers :
        "projects/${p}"
      ]
    ))
    if try(v.type != "bridge", true)
  }

  _perimeters_names = distinct(concat(keys(var.perimeters), [
    for k, v in local._data.perimeters : k
    if try(v.type != "bridge", true)
  ]))

  data = {
    service_perimeters_bridge = {
      for k, v in local._perimeters :
      k => {
        spec_resources = (
          v.dry_run
          ? flatten([for p in v.members : local._perimeters_projects[p]])
          : null
        )

        status_resources = (
          v.dry_run
          ? null
          : flatten([for p in v.members : local._perimeters_projects[p]])
        )

        use_explicit_dry_run_spec = v.dry_run
      }
      if try(v.type == "bridge", false)
    }


    service_perimeters_regular = {
      for k, v in local._perimeters :
      k => {
        spec = v.dry_run ? merge(v, {
          ingress_policies    = v.ingress_policies
          restricted_services = try(v.restricted_services, local.restricted_services)
          resources           = local._perimeters_projects[k]
        }) : null

        status = !v.dry_run ? merge(v, {
          ingress_policies    = v.ingress_policies
          restricted_services = try(v.restricted_services, local.restricted_services)
          resources           = local._perimeters_projects[k]
        }) : null

        use_explicit_dry_run_spec = v.dry_run
      }
      if try(v.type != "bridge", true)
    }
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

  restricted_services = yamldecode(file(var.factories_config.restricted_services))
}

module "vpc-sc-discovery" {
  source           = "../../../modules/projects-data-source"
  for_each         = var.resource_discovery.enabled ? local._perimeters : tomap({})
  parent           = coalesce(var.root_node, "organizations/${var.organization.id}")
  ignore_folders   = var.resource_discovery.ignore_folders
  ignore_projects  = var.resource_discovery.ignore_projects
  include_projects = var.resource_discovery.include_projects
  query            = try(each.value.resources_filter, "state:ACTIVE")
}

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if the default perimeter is defined
  count         = length(local._perimeters) > 0 ? 1 : 0
  access_policy = var.access_policy
  access_policy_create = var.access_policy != null ? null : {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }

  access_levels    = var.access_levels
  egress_policies  = var.egress_policies
  factories_config = var.factories_config
  ingress_policies = merge(
    local.fast_ingress_policies,
    var.ingress_policies
  )
  service_perimeters_bridge  = local.data.service_perimeters_bridge
  service_perimeters_regular = local.data.service_perimeters_regular
}
