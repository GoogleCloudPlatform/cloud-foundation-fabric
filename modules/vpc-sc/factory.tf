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
        description = try(v.description, null)
        title       = try(v.title, null)
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
          roles     = try(v.to.roles, [])
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
          roles     = try(v.to.roles, [])
        }
      }
    }
    perimeters = {
      for k, v in local._data.perimeters :
      k => {
        description             = try(v.description, null)
        ignore_resource_changes = try(v.ignore_resource_changes, false)
        title                   = try(v.title, null)
        spec = !can(v.spec) ? null : merge(v.spec, {
          access_levels           = try(v.spec.access_levels, [])
          egress_policies         = try(v.spec.egress_policies, [])
          ingress_policies        = try(v.spec.ingress_policies, [])
          restricted_services     = try(v.spec.restricted_services, [])
          resources               = try(v.spec.resources, [])
          vpc_accessible_services = try(v.spec.vpc_accessible_services, null)
        })
        status = !can(v.status) ? null : merge(v.status, {
          access_levels           = try(v.status.access_levels, [])
          egress_policies         = try(v.status.egress_policies, [])
          ingress_policies        = try(v.status.ingress_policies, [])
          restricted_services     = try(v.status.restricted_services, [])
          resources               = try(v.status.resources, [])
          vpc_accessible_services = try(v.status.vpc_accessible_services, null)
        })
        use_explicit_dry_run_spec = try(v.use_explicit_dry_run_spec, false)
      }
    }
  }
  # TODO: add checks that emulate the variable validations
}
