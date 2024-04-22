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
  vpc_sc_ingress_policies = var.logging == null ? {} : {
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
  vpc_sc_perimeter = (
    var.vpc_sc.perimeter_default == null
    ? null
    : merge(var.vpc_sc.perimeter_default, {
      ingress_policies = concat(
        var.vpc_sc.perimeter_default.ingress_policies,
        ["fast-org-log-sinks"]
      )
      restricted_services = yamldecode(file(
        var.factories_config.vpc_sc.restricted_services
      ))
      resources = distinct(concat(
        var.vpc_sc.perimeter_default.resources,
        var.vpc_sc.resource_discovery.enabled != true ? [] : [
          for v in module.vpc-sc-discovery[0].project_numbers :
          "projects/${v}"
        ]
      ))
    })
  )
}

module "vpc-sc-discovery" {
  source           = "../../../modules/projects-data-source"
  count            = var.vpc_sc.resource_discovery.enabled == true ? 1 : 0
  parent           = "organizations/${var.organization.id}"
  ignore_folders   = var.vpc_sc.resource_discovery.ignore_folders
  ignore_projects  = var.vpc_sc.resource_discovery.ignore_projects
  include_projects = var.vpc_sc.resource_discovery.include_projects
}

# TODO(ludomagno): allow passing in restricted services via variable and factory file
# TODO(ludomagno): implement vpc accessible services via variable or factory file

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if the default perimeter is defined
  count         = var.vpc_sc.perimeter_default == null ? 0 : 1
  access_policy = null
  access_policy_create = {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }
  access_levels   = var.vpc_sc.access_levels
  egress_policies = var.vpc_sc.egress_policies
  ingress_policies = merge(
    var.vpc_sc.ingress_policies,
    local.vpc_sc_ingress_policies
  )
  factories_config = var.factories_config.vpc_sc
  service_perimeters_regular = {
    default = {
      spec = (
        var.vpc_sc.perimeter_default.dry_run ? local.vpc_sc_perimeter : null
      )
      status = (
        !var.vpc_sc.perimeter_default.dry_run ? local.vpc_sc_perimeter : null
      )
      use_explicit_dry_run_spec = var.vpc_sc.perimeter_default.dry_run
    }
  }
}
