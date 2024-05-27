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
  _data_paths = {
    for k in ["access_levels", "egress_policies", "ingress_policies"] : k => (
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
          }, c)
        ]
      }
    }
    egress_policies = {
      for k, v in local._data.egress_policies : k => {
        from = merge({
          identity_type = null
          identities    = null
        }, try(v.from, {}))
        to = {
          operations = [
            for o in try(v.to.operations, []) : merge({
              method_selectors     = []
              permission_selectors = []
              service_name         = null
            }, o)
          ]
          resources              = try(v.to.resources, [])
          resource_type_external = try(v.to.resource_type_external, false)
        }
      }
    }
    ingress_policies = {
      for k, v in local._data.ingress_policies : k => {
        from = merge({
          access_levels = []
          identity_type = null
          identities    = null
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
  }
  # TODO: add checks that emulate the variable validations
}
