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

# tfdoc:file:description IAM bindings.

locals {
  _custom_roles_path = pathexpand(
    coalesce(var.factories_config.custom_roles, "-")
  )
  _custom_roles = {
    for f in try(fileset(local._custom_roles_path, "*.yaml"), []) :
    replace(f, ".yaml", "") => yamldecode(
      file("${local._custom_roles_path}/${f}")
    )
  }
  # get the set of IAM by principals roles
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  # recompose the principals under each role
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  custom_role_ids = {
    for k, v in google_organization_iam_custom_role.roles :
    # build the string manually so that role IDs can be used as map
    # keys (useful for folder/organization/project-level iam bindings)
    (k) => "${var.organization_id}/roles/${local.custom_roles[k].name}"
  }
  custom_roles = merge(
    {
      for k, v in local._custom_roles : k => {
        name        = lookup(v, "name", k)
        permissions = v["includedPermissions"]
      }
    },
    {
      for k, v in var.custom_roles : k => {
        name        = k
        permissions = v
      }
    }
  )
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  iam_bindings_additive = merge(
    var.iam_bindings_additive,
    [
      for principal, roles in var.iam_by_principals_additive : {
        for role in roles :
        "iam-bpa:${principal}-${role}" => {
          member    = principal
          role      = role
          condition = null
        }
      }
    ]...
  )
}

# we use a different key for custom roles to allow referring to the role alias
# in Terraform, while still being able to define unique role names

check "custom_roles" {
  assert {
    condition = (
      length(local.custom_roles) == length({
        for k, v in local.custom_roles : v.name => null
      })
    )
    error_message = "Duplicate role name in custom roles."
  }
}

resource "google_organization_iam_custom_role" "roles" {
  for_each    = local.custom_roles
  org_id      = local.organization_id_numeric
  role_id     = each.value.name
  title       = "Custom role ${each.value.name}"
  description = "Terraform-managed."
  permissions = each.value.permissions
}

resource "google_organization_iam_binding" "authoritative" {
  for_each = local.iam
  org_id   = local.organization_id_numeric
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_organization_iam_binding" "bindings" {
  for_each = var.iam_bindings
  org_id   = local.organization_id_numeric
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = templatestring(each.value.condition.expression, var.context.condition_vars)
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  # ensuring that custom role exists is left to the caller, by leveraging custom_role_id output
}

resource "google_organization_iam_member" "bindings" {
  for_each = local.iam_bindings_additive
  org_id   = local.organization_id_numeric
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member   = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = templatestring(each.value.condition.expression, var.context.condition_vars)
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  # ensuring that custom role exists is left to the caller, by leveraging custom_role_id output
}
