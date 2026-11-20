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

# tfdoc:file:description Project-level organization policies.

locals {
  _factory_data_path = pathexpand(coalesce(var.factories_config.org_policies, "-"))
  _factory_data_raw = merge([
    for f in try(fileset(local._factory_data_path, "*.yaml"), []) :
    yamldecode(file("${local._factory_data_path}/${f}"))
  ]...)
  # simulate applying defaults to data coming from yaml files
  _factory_data = {
    for k, v in local._factory_data_raw :
    k => {
      inherit_from_parent = try(v.inherit_from_parent, null)
      reset               = try(v.reset, null)
      rules = [
        for r in try(v.rules, []) : {
          # use try() not can(), as can() is true for explicit YAML nulls
          allow = try(r.allow, null) != null ? {
            all    = try(r.allow.all, null)
            values = try(r.allow.values, null)
          } : null
          deny = try(r.deny, null) != null ? {
            all    = try(r.deny.all, null)
            values = try(r.deny.values, null)
          } : null
          enforce = try(r.enforce, null)
          condition = {
            description = try(r.condition.description, null)
            expression  = try(r.condition.expression, null)
            location    = try(r.condition.location, null)
            title       = try(r.condition.title, null)
          }
          parameters = try(r.parameters, null)
        }
      ]
    }
  }
  _org_policies = merge(local._factory_data, var.org_policies)
  org_policies = {
    for k, v in local._org_policies :
    k => merge(v, {
      is_boolean_policy = (
        alltrue([for r in v.rules : r.allow == null && r.deny == null])
      )
      rules = [
        for r in v.rules :
        merge(r, {
          # check != null not can(), as can() is true for normalized nulls
          allow = r.allow == null ? null : merge(r.allow, {
            values = (
              r.allow.values == null
              ? null
              : [
                for x in r.allow.values :
                templatestring(x, var.context.condition_vars)
              ]
            )
          })
          deny = r.deny == null ? null : merge(r.deny, {
            values = (
              r.deny.values == null
              ? null
              : [
                for x in r.deny.values :
                templatestring(x, var.context.condition_vars)
              ]
            )
          })
          condition = {
            description = (
              r.condition.description == null
              ? null
              : templatestring(
                r.condition.description, var.context.condition_vars
              )
            )
            expression = (
              r.condition.expression == null
              ? null
              : templatestring(
                r.condition.expression, var.context.condition_vars
              )
            )
            location = (
              r.condition.location == null
              ? null
              : templatestring(
                r.condition.location, var.context.condition_vars
              )
            )
            title = (
              r.condition.title == null
              ? null
              : templatestring(
                r.condition.title, var.context.condition_vars
              )
            )
          }
          has_values = (
            length(coalesce(try(r.allow.values, []), [])) > 0 ||
            length(coalesce(try(r.deny.values, []), [])) > 0
          )
          parameters = (
            r.parameters == null
            ? null
            : templatestring(r.parameters, var.context.condition_vars)
          )
        })
      ]
    })
  }
}

resource "google_org_policy_policy" "default" {
  for_each = toset([
    for k, v in local._org_policies : trimprefix(k, "dry_run:")
  ])
  name   = "projects/${local.project.project_id}/policies/${each.value}"
  parent = "projects/${local.project.project_id}"
  dynamic "spec" {
    for_each = lookup(local.org_policies, each.value, null) != null ? [local.org_policies[each.value]] : []
    iterator = spec
    content {
      inherit_from_parent = spec.value.inherit_from_parent
      reset               = spec.value.reset
      dynamic "rules" {
        for_each = spec.value.rules
        iterator = rule
        content {
          allow_all  = try(rule.value.allow.all, false) == true ? "TRUE" : null
          deny_all   = try(rule.value.deny.all, false) == true ? "TRUE" : null
          parameters = rule.value.parameters
          enforce = (
            spec.value.is_boolean_policy && rule.value.enforce != null
            ? upper(tostring(rule.value.enforce))
            : null
          )
          dynamic "condition" {
            for_each = rule.value.condition.expression != null ? [1] : []
            content {
              description = rule.value.condition.description
              expression  = rule.value.condition.expression
              location    = rule.value.condition.location
              title       = rule.value.condition.title
            }
          }
          dynamic "values" {
            for_each = rule.value.has_values ? [1] : []
            content {
              allowed_values = try(rule.value.allow.values, null)
              denied_values  = try(rule.value.deny.values, null)
            }
          }
        }
      }
    }
  }

  dynamic "dry_run_spec" {
    for_each = lookup(local.org_policies, "dry_run:${each.value}", null) != null ? [local.org_policies["dry_run:${each.value}"]] : []
    iterator = spec
    content {
      inherit_from_parent = spec.value.inherit_from_parent
      reset               = spec.value.reset
      dynamic "rules" {
        for_each = spec.value.rules
        iterator = rule
        content {
          allow_all  = try(rule.value.allow.all, false) == true ? "TRUE" : null
          deny_all   = try(rule.value.deny.all, false) == true ? "TRUE" : null
          parameters = rule.value.parameters
          enforce = (
            spec.value.is_boolean_policy && rule.value.enforce != null
            ? upper(tostring(rule.value.enforce))
            : null
          )
          dynamic "condition" {
            for_each = rule.value.condition.expression != null ? [1] : []
            content {
              description = rule.value.condition.description
              expression  = rule.value.condition.expression
              location    = rule.value.condition.location
              title       = rule.value.condition.title
            }
          }
          dynamic "values" {
            for_each = rule.value.has_values ? [1] : []
            content {
              allowed_values = try(rule.value.allow.values, null)
              denied_values  = try(rule.value.deny.values, null)
            }
          }
        }
      }
    }
  }

  depends_on = [google_project_service.org_policy_service]
}
