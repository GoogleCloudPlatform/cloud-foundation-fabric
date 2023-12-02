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

# tfdoc:file:description Generic and OSLogin-specific IAM bindings and roles.

# IAM notes:
# - external users need to have accepted the invitation email to join

locals {
  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }

  _factory_custom_roles = { for r in
    flatten([for f in try(fileset(var.factories_config.custom_roles, "*.yaml"), []) :
      [for role_name, permissions in yamldecode(file("${var.factories_config.custom_roles}/${f}")) : {
        role_name   = role_name
        permissions = permissions
      }]
  ]) : r.role_name => r.permissions }

  custom_roles = merge(
    var.custom_roles,
    local._factory_custom_roles
  )

  _factory_iam_bindings = { for b in
    flatten([for f in try(fileset(var.factories_config.bindings, "*.yaml"), []) :
      [for binding_name, data in yamldecode(file("${var.factories_config.bindings}/${f}")) : {
        binding_name = binding_name
        data = {
          members = data.members
          role    = try(google_project_iam_custom_role.roles[data.role], data.role)
          condition = {
            title       = try(data.condition.title, "")
            expression  = try(data.condition.expression, "")
            description = try(data.condition.description, "")
          }
        }
      }]
  ]) : b.binding_name => b.data }

  _factory_iam_bindings_additive = { for b in
    flatten([for f in try(fileset(var.factories_config.bindings_additive_, "*.yaml"), []) :
      [for binding_name, data in yamldecode(file("${var.factories_config.bindings_additive_}/${f}")) : {
        binding_name = binding_name
        data = {
          members = data.members
          role    = try(google_project_iam_custom_role.roles[data.role], data.role)
          condition = {
            title       = try(data.condition.title, "")
            expression  = try(data.condition.expression, "")
            description = try(data.condition.description, "")
          }
        }
      }]
  ]) : b.binding_name => b.data }

  iam_bindings = merge(
    var.iam_bindings,
    local._factory_iam_bindings
  )
  iam_bindings_additive = merge(
    var.iam_bindings,
    local._factory_iam_bindings_additive
  )
}

resource "google_project_iam_custom_role" "roles" {
  for_each    = local.custom_roles
  project     = local.project.project_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed."
  permissions = each.value
  depends_on  = [local.custom_roles]
}

resource "google_project_iam_binding" "authoritative" {
  for_each = local.iam
  project  = local.project.project_id
  role     = each.key
  members  = each.value
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_binding" "bindings" {
  for_each = local.iam_bindings
  project  = local.project.project_id
  role     = each.value.role
  members  = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles,
    local.iam_bindings
  ]
}

resource "google_project_iam_member" "bindings" {
  for_each = local.iam_bindings_additive
  project  = local.project.project_id
  role     = each.value.role
  member   = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}
