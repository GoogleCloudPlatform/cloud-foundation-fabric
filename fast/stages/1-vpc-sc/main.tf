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
  perimeters = {
    for k, v in var.perimeters : k => merge(v, {
      restricted_services = (
        v.restricted_services == null
        ? local.restricted_services
        : v.restricted_services
      )
      resources = distinct(concat(
        v.resources,
        k != "default" || var.resource_discovery.enabled != true ? [] : [
          for v in module.vpc-sc-discovery[0].project_numbers :
          "projects/${v}"
        ]
      ))
    })
  }
  restricted_services = yamldecode(file("data/restricted-services.yaml"))
}

module "vpc-sc-discovery" {
  source           = "../../../modules/projects-data-source"
  count            = var.resource_discovery.enabled == true ? 1 : 0
  parent           = coalesce(var.root_node, "organizations/${var.organization.id}")
  ignore_folders   = var.resource_discovery.ignore_folders
  ignore_projects  = var.resource_discovery.ignore_projects
  include_projects = var.resource_discovery.include_projects
}

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if the default perimeter is defined
  count         = var.perimeters.default == null ? 0 : 1
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
  service_perimeters_regular = {
    for k, v in local.perimeters : k => {
      spec                      = v.dry_run ? v : null
      status                    = !v.dry_run ? v : null
      use_explicit_dry_run_spec = v.dry_run
    }
  }
}
