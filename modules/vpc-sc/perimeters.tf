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

# tfdoc:file:description Regular service perimeter resources.

locals {
  egress_policies  = merge(local.data.egress_policies, var.egress_policies)
  ingress_policies = merge(local.data.ingress_policies, var.ingress_policies)
  perimeters       = merge(local.data.perimeters, var.perimeters)
  _undefined_egress_policies = {
    for k, v in local.perimeters :
    k => setsubtract(concat(try(v.spec.egress_policies, []), try(v.status.egress_policies, [])), keys(local.egress_policies))
  }
  _undefined_ingress_policies = {
    for k, v in local.perimeters :
    k => setsubtract(concat(try(v.spec.ingress_policies, []), try(v.status.ingress_policies, [])), keys(local.ingress_policies))
  }
}

resource "google_access_context_manager_service_perimeter" "regular" {
  for_each = {
    for k, v in local.perimeters : k => v if !v.ignore_resource_changes
  }
  parent                    = "accessPolicies/${local.access_policy}"
  name                      = "accessPolicies/${local.access_policy}/servicePerimeters/${each.key}"
  description               = each.value.description
  title                     = coalesce(each.value.title, each.key)
  perimeter_type            = "PERIMETER_TYPE_REGULAR"
  use_explicit_dry_run_spec = each.value.use_explicit_dry_run_spec
  dynamic "spec" {
    for_each = each.value.spec == null ? [] : [each.value.spec]
    iterator = spec
    content {
      access_levels = (
        spec.value.access_levels == null ? null : [
          for k in spec.value.access_levels :
          try(google_access_context_manager_access_level.basic[k].id, k)
        ]
      )
      resources = flatten([
        for r in spec.value.resources : try(
          local.ctx.resource_sets[r],
          [local.ctx.project_numbers[r]],
          [local.project_numbers[r]], [r]
        )
      ])
      restricted_services = flatten([
        for r in coalesce(spec.value.restricted_services, []) :
        lookup(local.ctx.service_sets, r, [r])
      ])

      dynamic "egress_policies" {
        for_each = [
          for k in coalesce(spec.value.egress_policies, []) :
          merge(local.egress_policies[k], { key = k })
        ]
        iterator = policy
        content {
          title = coalesce(policy.value.title, policy.value.key)
          dynamic "egress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities = flatten([
                for i in policy.value.from.identities : (
                  startswith(i, "$identity_sets:")
                  ? lookup(local.ctx.identity_sets, i, [i])
                  : lookup(local.ctx.iam_principals_list, i, [i])
                )
              ])
              source_restriction = (
                length(policy.value.from.access_levels) > 0 || length(policy.value.from.resources) > 0
                ? "SOURCE_RESTRICTION_ENABLED"
                : "SOURCE_RESTRICTION_DISABLED"
              )
              dynamic "sources" {
                for_each = policy.value.from.access_levels
                iterator = access_level
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[access_level.value].id,
                    access_level.value
                  )
                }
              }
              dynamic "sources" {
                for_each = flatten([
                  for r in policy.value.from.resources : try(
                    local.ctx.resource_sets[r],
                    [local.ctx.project_numbers[r]],
                    [local.project_numbers[r]], [r]
                  )
                ])
                iterator = resource
                content {
                  resource = resource.value
                }
              }
            }
          }
          dynamic "egress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              external_resources = policy.value.to.external_resources
              resources = flatten([
                for r in policy.value.to.resources : try(
                  local.ctx.resource_sets[r],
                  [local.ctx.project_numbers[r]],
                  [local.project_numbers[r]], [r]
                )
              ])
              roles = policy.value.to.roles
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.key
                    }
                  }
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.permission_selectors, []))
                    content {
                      permission = method_selectors.key
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = [
          for k in coalesce(spec.value.ingress_policies, []) :
          merge(local.ingress_policies[k], { key = k })
        ]
        iterator = policy
        content {
          title = coalesce(policy.value.title, policy.value.key)
          dynamic "ingress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities = flatten([
                for i in policy.value.from.identities : (
                  startswith(i, "$identity_sets:")
                  ? lookup(local.ctx.identity_sets, i, [i])
                  : lookup(local.ctx.iam_principals_list, i, [i])
                )
              ])
              dynamic "sources" {
                for_each = toset(policy.value.from.access_levels)
                iterator = s
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[s.value].id, s.value
                  )
                }
              }
              dynamic "sources" {
                for_each = flatten([
                  for r in policy.value.from.resources : try(
                    local.ctx.resource_sets[r],
                    [local.ctx.project_numbers[r]],
                    [local.project_numbers[r]], [r]
                  )
                ])
                content {
                  resource = sources.value
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = flatten([
                for r in policy.value.to.resources : try(
                  local.ctx.resource_sets[r],
                  [local.ctx.project_numbers[r]],
                  [local.project_numbers[r]], [r]
                )
              ])
              roles = policy.value.to.roles
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.value
                    }
                  }
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.permission_selectors, []))
                    content {
                      permission = method_selectors.value
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "vpc_accessible_services" {
        for_each = spec.value.vpc_accessible_services == null ? [] : [""]
        content {
          allowed_services = flatten([
            for r in spec.value.vpc_accessible_services.allowed_services :
            lookup(local.ctx.service_sets, r, [r])
          ])
          enable_restriction = spec.value.vpc_accessible_services.enable_restriction
        }
      }

    }
  }
  dynamic "status" {
    for_each = each.value.status == null ? [] : [each.value.status]
    iterator = status
    content {
      access_levels = (
        status.value.access_levels == null ? null : [
          for k in status.value.access_levels :
          try(google_access_context_manager_access_level.basic[k].id, k)
        ]
      )
      resources = flatten([
        for r in status.value.resources : try(
          local.ctx.resource_sets[r],
          [local.ctx.project_numbers[r]],
          [local.project_numbers[r]], [r]
        )
      ])
      restricted_services = flatten([
        for r in coalesce(status.value.restricted_services, []) :
        lookup(local.ctx.service_sets, r, [r])
      ])

      dynamic "egress_policies" {
        for_each = [
          for k in coalesce(status.value.egress_policies, []) :
          merge(local.egress_policies[k], { key = k })
        ]
        iterator = policy
        content {
          title = coalesce(policy.value.title, policy.value.key)
          dynamic "egress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities = flatten([
                for i in policy.value.from.identities : (
                  startswith(i, "$identity_sets:")
                  ? lookup(local.ctx.identity_sets, i, [i])
                  : lookup(local.ctx.iam_principals_list, i, [i])
                )
              ])
              source_restriction = (
                length(policy.value.from.access_levels) > 0 || length(policy.value.from.resources) > 0
                ? "SOURCE_RESTRICTION_ENABLED"
                : "SOURCE_RESTRICTION_DISABLED"
              )
              dynamic "sources" {
                for_each = policy.value.from.access_levels
                iterator = access_level
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[access_level.value].id,
                    access_level.value
                  )
                }
              }
              dynamic "sources" {
                for_each = flatten([
                  for r in policy.value.from.resources : try(
                    local.ctx.resource_sets[r],
                    [local.ctx.project_numbers[r]],
                    [local.project_numbers[r]], [r]
                  )
                ])
                iterator = resource
                content {
                  resource = resource.value
                }
              }
            }
          }
          dynamic "egress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              external_resources = policy.value.to.external_resources
              resources = flatten([
                for r in policy.value.to.resources : try(
                  local.ctx.resource_sets[r],
                  [local.ctx.project_numbers[r]],
                  [local.project_numbers[r]], [r]
                )
              ])
              roles = policy.value.to.roles
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.key
                    }
                  }
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.permission_selectors, []))
                    content {
                      permission = method_selectors.key
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "ingress_policies" {
        for_each = [
          for k in coalesce(status.value.ingress_policies, []) :
          merge(local.ingress_policies[k], { key = k })
        ]
        iterator = policy
        content {
          title = coalesce(policy.value.title, policy.value.key)
          dynamic "ingress_from" {
            for_each = policy.value.from == null ? [] : [""]
            content {
              identity_type = policy.value.from.identity_type
              identities = flatten([
                for i in policy.value.from.identities : (
                  startswith(i, "$identity_sets:")
                  ? lookup(local.ctx.identity_sets, i, [i])
                  : lookup(local.ctx.iam_principals_list, i, [i])
                )
              ])
              dynamic "sources" {
                for_each = toset(policy.value.from.access_levels)
                iterator = s
                content {
                  access_level = try(
                    google_access_context_manager_access_level.basic[s.value].id,
                    s.value
                  )
                }
              }
              dynamic "sources" {
                for_each = flatten([
                  for r in policy.value.from.resources : try(
                    local.ctx.resource_sets[r],
                    [local.ctx.project_numbers[r]],
                    [local.project_numbers[r]], [r]
                  )
                ])
                content {
                  resource = sources.value
                }
              }
            }
          }
          dynamic "ingress_to" {
            for_each = policy.value.to == null ? [] : [""]
            content {
              resources = flatten([
                for r in policy.value.to.resources : try(
                  local.ctx.resource_sets[r],
                  [local.ctx.project_numbers[r]],
                  [local.project_numbers[r]], [r]
                )
              ])
              roles = policy.value.to.roles
              dynamic "operations" {
                for_each = toset(policy.value.to.operations)
                iterator = o
                content {
                  service_name = o.value.service_name
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.method_selectors, []))
                    content {
                      method = method_selectors.value
                    }
                  }
                  dynamic "method_selectors" {
                    for_each = toset(coalesce(o.value.permission_selectors, []))
                    content {
                      permission = method_selectors.value
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "vpc_accessible_services" {
        for_each = status.value.vpc_accessible_services == null ? [] : [""]
        content {
          allowed_services = flatten([
            for r in status.value.vpc_accessible_services.allowed_services :
            lookup(local.ctx.service_sets, r, [r])
          ])
          enable_restriction = status.value.vpc_accessible_services.enable_restriction
        }
      }

    }
  }
  lifecycle {
    precondition {
      condition     = length(local._undefined_ingress_policies[each.key]) == 0
      error_message = "Undefined ingress policies: ${join(", ", local._undefined_ingress_policies[each.key])}"
    }
    precondition {
      condition     = length(local._undefined_egress_policies[each.key]) == 0
      error_message = "Undefined egress policies: ${join(", ", local._undefined_egress_policies[each.key])}"
    }
  }
  depends_on = [
    google_access_context_manager_access_policy.default,
    google_access_context_manager_access_level.basic
  ]
}
