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

locals {
  _vpc_sc_vpc_accessible_services = null
  _vpc_sc_restricted_services = yamldecode(
    file("${path.module}/vpc-sc-restricted-services.yaml")
  )
  # compute the number of projects in each perimeter to detect which to create
  vpc_sc_counts = {
    for k, v in var.vpc_sc_perimeters : k => length(v.resources)
  }
  # define dry run spec at file level for convenience
  vpc_sc_explicit_dry_run_spec = true
  # compute perimeter bridge resources (projects)
  vpc_sc_bridge_resources = {
    landing_to_dev = concat(
      var.vpc_sc_perimeters.landing.resources,
      var.vpc_sc_perimeters.dev.resources
    )
    landing_to_prod = concat(
      var.vpc_sc_perimeters.landing.resources,
      var.vpc_sc_perimeters.prod.resources
    )
  }
  # compute spec/status for each perimeter
  vpc_sc_perimeters = {
    dev = merge(var.vpc_sc_perimeters.dev, {
      restricted_services     = local._vpc_sc_restricted_services
      vpc_accessible_services = local._vpc_sc_vpc_accessible_services
    })
  }
}

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if we have projects defined for perimeters
  count         = anytrue([for k, v in local.vpc_sc_counts : v > 0]) ? 1 : 0
  access_policy = null
  access_policy_create = {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }
  access_levels    = var.vpc_sc_access_levels
  egress_policies  = var.vpc_sc_egress_policies
  ingress_policies = var.vpc_sc_ingress_policies
  service_perimeters_bridge = merge(
    # landing to dev, only we have projects in landing and dev perimeters
    local.vpc_sc_counts.landing * local.vpc_sc_counts.dev == 0 ? {} : {
      landing_to_dev = {
        spec_resources = (
          local.vpc_sc_explicit_dry_run_spec
          ? local.vpc_sc_bridge_resources.landing_to_dev
          : null
        )
        status_resources = (
          local.vpc_sc_explicit_dry_run_spec
          ? null
          : local.vpc_sc_bridge_resources.landing_to_dev
        )
        use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
      }
    },
    # landing to prod, only we have projects in landing and prod perimeters
    local.vpc_sc_counts.landing * local.vpc_sc_counts.prod == 0 ? {} : {
      landing_to_prod = {
        spec_resources = (
          local.vpc_sc_explicit_dry_run_spec
          ? local.vpc_sc_bridge_resources.landing_to_prod
          : null
        )
        status_resources = (
          local.vpc_sc_explicit_dry_run_spec
          ? null
          : local.vpc_sc_bridge_resources.landing_to_prod
        )
        use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
      }
    }
  )
  # regular type perimeters
  service_perimeters_regular = merge(
    # dev if we have projects in var.vpc_sc_perimeter_projects.dev
    local.vpc_sc_counts.dev == 0 ? {} : {
      dev = {
        spec = (
          local.vpc_sc_explicit_dry_run_spec
          ? var.vpc_sc_perimeters.dev
          : null
        )
        status = (
          local.vpc_sc_explicit_dry_run_spec
          ? null
          : var.vpc_sc_perimeters.dev
        )
        use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
      }
    },
    # landing if we have projects in var.vpc_sc_perimeter_projects.landing
    local.vpc_sc_counts.landing == 0 ? {} : {
      landing = {
        spec = (
          local.vpc_sc_explicit_dry_run_spec
          ? var.vpc_sc_perimeters.landing
          : null
        )
        status = (
          local.vpc_sc_explicit_dry_run_spec
          ? null
          : var.vpc_sc_perimeters.landing
        )
        use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
      }
    },
    # prod if we have projects in var.vpc_sc_perimeter_projects.prod
    local.vpc_sc_counts.prod == 0 ? {} : {
      prod = {
        spec = (
          local.vpc_sc_explicit_dry_run_spec
          ? var.vpc_sc_perimeters.prod
          : null
        )
        status = (
          local.vpc_sc_explicit_dry_run_spec
          ? null
          : var.vpc_sc_perimeters.prod
        )
        use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
      }
    },
  )
}
