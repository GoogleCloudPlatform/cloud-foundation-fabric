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
  _data = {
    for k, v in local._data_paths : k => {
      for f in try(fileset(v, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => yamldecode(file("${v}/${f}"))
    }
  }
  _data_paths = {
    for k in ["access_levels", "egress_policies", "ingress_policies", "perimeters"] : k => (
      var.factories_config[k] == null
      ? null
      : pathexpand(var.factories_config[k])
    )
  }
  data = {
    access_levels = {
      for k, v in local._data.access_levels : k => {
        combining_function = try(v.combining_function, null)
        description        = try(v.description, null)
        conditions = [
          for c in try(v.conditions, []) : merge({
            device_policy          = null
            ip_subnetworks         = []
            members                = []
            negate                 = null
            regions                = []
            required_access_levels = []
            vpc_subnets            = {}
          }, c)
        ]
      }
    }
    egress_policies = {
      for k, v in local._data.egress_policies : k => {
        title = try(v.title, null)
        from = merge({
          access_levels = []
          identity_type = null
          identities    = []
          resources     = []
        }, try(v.from, {}))
        to = {
          external_resources = try(v.to.external_resources, null)
          operations = [
            for o in try(v.to.operations, []) : merge({
              method_selectors     = []
              permission_selectors = []
              service_name         = null
            }, o)
          ]
          resources = try(v.to.resources, [])
        }
      }
    }
    ingress_policies = {
      for k, v in local._data.ingress_policies : k => {
        title = try(v.title, null)
        from = merge({
          access_levels = []
          identity_type = null
          identities    = []
          resources     = []
        }, try(v.from, {}))
        to = {
          operations = [
            for o in try(v.to.operations, []) : merge({
              method_selectors     = []
              permission_selectors = []
              service_name         = null
            }, o)
          ]
          resources = try(v.to.resources, [])
        }
      }
    }
    service_perimeters_bridge = {
      for k, v in local._data.perimeters :
      k => {
        description = try(v.description, null)
        spec_resources = (
          try(v.dry_run, false)
          ? distinct(concat(v.resources,
          flatten([for p in v.perimeters : var.dynamic_projects_map[p]])))
          : null
        )

        status_resources = (
          !try(v.dry_run, false)
          ? distinct(concat(v.resources,
          flatten([for p in v.perimeters : var.dynamic_projects_map[p]])))
          : null
        )

        use_explicit_dry_run_spec = try(v.dry_run, false)
      }
      if try(v.type == "bridge", false)
    }
    service_perimeters_regular = {
      for k, v in local._data.perimeters :
      k => {
        description = try(v.description, null)
        spec = try(v.dry_run, false) ? merge(v, {
          access_levels       = try(v.access_levels, [])
          egress_policies     = try(v.egress_policies, [])
          ingress_policies    = try(v.ingress_policies, [])
          restricted_services = try(v.restricted_services, local.restricted_services)
          resources = distinct(concat(try(v.resources, []),
          try(var.dynamic_projects_map[k], [])))
          vpc_accessible_services = try(v.vpc_accessible_services, null)
        }) : null

        status = !try(v.dry_run, false) ? merge(v, {
          access_levels       = try(v.access_levels, [])
          egress_policies     = try(v.egress_policies, [])
          ingress_policies    = try(v.ingress_policies, [])
          restricted_services = try(v.restricted_services, local.restricted_services)
          resources = distinct(concat(try(v.resources, []),
          try(var.dynamic_projects_map[k], [])))
          vpc_accessible_services = try(v.vpc_accessible_services, null)
        }) : null

        use_explicit_dry_run_spec = try(v.dry_run, false)
      }
      if try(v.type != "bridge", true)
    }
  }
  restricted_services = try(yamldecode(file(var.factories_config.restricted_services)), [])
  # TODO: add checks that emulate the variable validations
}
