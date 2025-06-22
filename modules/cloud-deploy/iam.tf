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
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  _merge_target_iam = flatten([
    for kt, vt in var.targets : [
      for role in distinct(concat(keys(vt.iam), keys(local._target_iam_principals[vt.name]))) :
      {
        "project_id" = vt.project_id
        "region"     = vt.region
        "name"       = vt.name
        "role"       = role
        "members" = concat(
          try(vt.iam[role], []),
          try(local._target_iam_principals[vt.name][role], [])
        )
      }
    ]
  ])
  _target_iam_principal_roles = { for k, v in var.targets : v.name => distinct(flatten(values(v.iam_by_principals))) }
  _target_iam_principals = {
    for k, v in var.targets : v.name => {
      for r in local._target_iam_principal_roles[v.name] : r => [
        for kp, vp in v.iam_by_principals :
        kp if try(index(vp, r), null) != null
      ]
    }
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  target_iam = {
    for k, v in local._merge_target_iam : k => v
  }
  target_iam_bindings = merge([
    for k, v in var.targets : {
      for ki, vi in v.iam_bindings :
      "${ki}_${k}" => merge(vi, { "project_id" = v.project_id, "region" = v.region, "name" = v.name })
    }
  ]...)
  target_iam_bindings_additive = merge([
    for k, v in var.targets : {
      for ki, vi in v.iam_bindings_additive :
      "${ki}_${k}" => merge(vi, { "project_id" = v.project_id, "region" = v.region, "name" = v.name })
    }
  ]...)
}

resource "google_clouddeploy_delivery_pipeline_iam_binding" "authoritative" {
  for_each = local.iam
  project  = var.project_id
  location = var.region
  name     = var.name
  role     = each.key
  members  = each.value
}

resource "google_clouddeploy_delivery_pipeline_iam_binding" "bindings" {
  for_each = var.iam_bindings
  project  = var.project_id
  location = var.region
  name     = var.name
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
}

resource "google_clouddeploy_delivery_pipeline_iam_member" "bindings" {
  for_each = var.iam_bindings_additive
  project  = var.project_id
  location = var.region
  name     = var.name
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
}

resource "google_clouddeploy_target_iam_binding" "authoritative" {
  for_each = local.target_iam
  project  = coalesce(each.value.project_id, var.project_id)
  location = coalesce(each.value.region, var.region)
  name     = each.value.name
  role     = each.value.role
  members  = each.value.members
}

resource "google_clouddeploy_target_iam_binding" "bindings" {
  for_each = local.target_iam_bindings
  project  = coalesce(each.value.project_id, var.project_id)
  location = coalesce(each.value.region, var.region)
  name     = each.value.name
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
}

resource "google_clouddeploy_target_iam_member" "bindings" {
  for_each = local.target_iam_bindings_additive
  project  = coalesce(each.value.project_id, var.project_id)
  location = coalesce(each.value.region, var.region)
  name     = each.value.name
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
}
