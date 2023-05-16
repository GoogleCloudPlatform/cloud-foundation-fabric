/**
 * Copyright 2023 Google LLC
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
  # define dry run spec at file level for convenience
  vpc_sc_explicit_dry_run_spec = true
  vpc_sc_perimeters_spec_status = {
    for k, v in var.vpc_sc_perimeters : k => merge([
      v,
      {
        resources               = local._vpc_sc_perimeter_resources[k]
        restricted_services     = local._vpc_sc_restricted_services
        vpc_accessible_services = local._vpc_sc_vpc_accessible_services
        project_ids             = null
        folder_ids              = null
      },
    ]...) if local._vpc_sc_counts[k] > 0
  }
  vpc_sc_bridges_spec_status = {
    for v in var.vpc_sc_bridges : "${v.from}_to_${v.to}" =>
    sort(toset(flatten([
      local._vpc_sc_perimeter_resources[v.from],
      local._vpc_sc_perimeter_resources[v.to],
    ]))) if local._vpc_sc_counts[v.from] * local._vpc_sc_counts[v.to] > 0
  }
  vpc_sc_egress_policies = {
    for k, v in var.vpc_sc_egress_policies :
    k => {
      from = v.from
      to = merge(
        v.to,
        { resources = local._vpc_sc_egress_policies_resources_to[k] }
      )
    }
  }
  vpc_sc_ingress_policies = {
    for k, v in var.vpc_sc_ingress_policies :
    k => {
      from = merge(
        v.from,
        { resources = local._vpc_sc_ingress_policies_resources_from[k] }
      )
      to = merge(
        v.to,
        { resources = local._vpc_sc_ingress_policies_resources_to[k] }
      )
    }
  }
}

module "vpc-sc" {
  source = "../../../modules/vpc-sc"
  # only enable if we have projects defined for perimeters
  count         = length(keys(local.vpc_sc_perimeters_spec_status)) > 0 ? 1 : 0
  access_policy = null
  access_policy_create = {
    parent = "organizations/${var.organization.id}"
    title  = "default"
  }
  access_levels    = var.vpc_sc_access_levels
  egress_policies  = local.vpc_sc_egress_policies
  ingress_policies = local.vpc_sc_ingress_policies
  # bridge perimeters
  service_perimeters_bridge = {
    for k, v in local.vpc_sc_bridges_spec_status : k => {
      spec_resources = (
        local.vpc_sc_explicit_dry_run_spec ? v : null
      )
      status_resources = (
        local.vpc_sc_explicit_dry_run_spec ? null : v
      )
      use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
    }
  }
  # regular type perimeters
  service_perimeters_regular = {
    for k, v in local.vpc_sc_perimeters_spec_status : k => {
      spec = (
        local.vpc_sc_explicit_dry_run_spec ? v : null
      )
      status = (
        local.vpc_sc_explicit_dry_run_spec ? null : v
      )
      use_explicit_dry_run_spec = local.vpc_sc_explicit_dry_run_spec
    }
  }
}
