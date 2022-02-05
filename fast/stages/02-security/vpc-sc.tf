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
  # compute the number of projects in each perimeter to detect which to create
  vpc_sc_counts = {
    for k in ["dev", "landing", "prod"] : k => length(
      coalesce(try(local._vpc_sc_perimeter_projects[k], null), [])
    )
  }
  # dereference perimeter egress policy names to the actual objects
  vpc_sc_perimeter_egress_policies = {
    for k, v in coalesce(var.vpc_sc_perimeter_egress_policies, {}) :
    k => [
      for i in coalesce(v, []) : var.vpc_sc_egress_policies[i]
      if lookup(var.vpc_sc_egress_policies, i, null) != null
    ]
  }
  # dereference perimeter ingress policy names to the actual objects
  vpc_sc_perimeter_ingress_policies = {
    for k, v in coalesce(var.vpc_sc_perimeter_ingress_policies, {}) :
    k => [
      for i in coalesce(v, []) : var.vpc_sc_ingress_policies[i]
      if lookup(var.vpc_sc_ingress_policies, i, null) != null
    ]
  }
  # get the list of restricted services from the yaml file
  vpcsc_restricted_services = yamldecode(
    file("${path.module}/vpc-sc-restricted-services.yaml")
  )
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
  access_levels = coalesce(try(var.vpc_sc_access_levels, null), {})
  # bridge type perimeters
  service_perimeters_bridge = merge(
    # landing to dev, only we have projects in landing and dev perimeters
    local.vpc_sc_counts.landing * local.vpc_sc_counts.dev == 0 ? {} : {
      landing_to_dev = {
        status_resources = null
        spec_resources = concat(
          local._vpc_sc_perimeter_projects.landing,
          local._vpc_sc_perimeter_projects.dev
        )
        use_explicit_dry_run_spec = true
      }
    },
    # landing to prod, only we have projects in landing and prod perimeters
    local.vpc_sc_counts.landing * local.vpc_sc_counts.prod == 0 ? {} : {
      landing_to_prod = {
        status_resources = null
        spec_resources = concat(
          local._vpc_sc_perimeter_projects.landing,
          local._vpc_sc_perimeter_projects.prod
        )
        # set to null and switch spec and status above to enforce
        use_explicit_dry_run_spec = true
      }
    }
  )
  # regular type perimeters
  service_perimeters_regular = merge(
    # dev if we have projects in local._vpc_sc_perimeter_projects.dev
    local.vpc_sc_counts.dev == 0 ? {} : {
      dev = {
        spec = {
          access_levels = coalesce(
            try(var.vpc_sc_perimeter_access_levels.dev, null), []
          )
          resources           = local._vpc_sc_perimeter_projects.dev
          restricted_services = local.vpcsc_restricted_services
          egress_policies = try(
            local.vpc_sc_perimeter_egress_policies.dev, null
          )
          ingress_policies = try(
            local.vpc_sc_perimeter_ingress_policies.dev, null
          )
          # replace with commented block to enable vpc restrictions
          vpc_accessible_services = null
          # vpc_accessible_services = {
          #   allowed_services   = ["RESTRICTED-SERVICES"]
          #   enable_restriction = true
          # }
        }
        status = null
        # set to null and switch spec and status above to enforce
        use_explicit_dry_run_spec = true
      }
    },
    # prod if we have projects in local._vpc_sc_perimeter_projects.prod
    local.vpc_sc_counts.prod == 0 ? {} : {
      prod = {
        spec = {
          access_levels = coalesce(
            try(var.vpc_sc_perimeter_access_levels.prod, null), []
          )
          # combine the security project, and any specified in the variable
          resources           = local._vpc_sc_perimeter_projects.prod
          restricted_services = local.vpcsc_restricted_services
          egress_policies = try(
            local.vpc_sc_perimeter_egress_policies.prod, null
          )
          ingress_policies = try(
            local.vpc_sc_perimeter_ingress_policies.prod, null
          )
          # replace with commented block to enable vpc restrictions
          vpc_accessible_services = null
          # vpc_accessible_services = {
          #   allowed_services   = ["RESTRICTED-SERVICES"]
          #   enable_restriction = true
          # }
        }
        status = null
        # set to null and switch spec and status above to enforce
        use_explicit_dry_run_spec = true
      }
    },
    # prod if we have projects in local._vpc_sc_perimeter_projects.prod
    local.vpc_sc_counts.landing == 0 ? {} : {
      landing = {
        spec = {
          access_levels = coalesce(
            try(var.vpc_sc_perimeter_access_levels.landing, null), []
          )
          resources           = local._vpc_sc_perimeter_projects.landing
          restricted_services = local.vpcsc_restricted_services
          egress_policies = try(
            local.vpc_sc_perimeter_egress_policies.landing, null
          )
          ingress_policies = try(
            local.vpc_sc_perimeter_ingress_policies.landing, null
          )
          # replace with commented block to enable vpc restrictions
          vpc_accessible_services = null
          # vpc_accessible_services = {
          #   allowed_services   = ["RESTRICTED-SERVICES"]
          #   enable_restriction = true
          # }
        }
        status = null
        # set to null and switch spec and status above to enforce
        use_explicit_dry_run_spec = true
      }
    }
  )
}
