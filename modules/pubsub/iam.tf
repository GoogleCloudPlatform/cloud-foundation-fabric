/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the authoritative.
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
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  subscription_iam = flatten([
    for k, v in var.subscriptions : [
      for role, members in v.iam : {
        subscription = k
        role         = role
        members      = members
      }
    ]
  ])
  subscription_iam_bindings = merge([
    for k, v in var.subscriptions : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        subscription = k
        role         = data.role
        members      = data.members
        condition    = data.condition
      }
    }
  ]...)
  subscription_iam_bindings_additive = merge([
    for k, v in var.subscriptions : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        subscription = k
        role         = data.role
        member       = data.member
        condition    = data.condition
      }
    }
  ]...)
}

resource "google_pubsub_topic_iam_binding" "authoritative" {
  for_each = local.iam
  project  = local.project_id
  topic    = google_pubsub_topic.default.name
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_pubsub_topic_iam_binding" "bindings" {
  for_each = var.iam_bindings
  topic    = google_pubsub_topic.default.name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_pubsub_topic_iam_member" "bindings" {
  for_each = var.iam_bindings_additive
  topic    = google_pubsub_topic.default.name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_pubsub_subscription_iam_binding" "authoritative" {
  for_each = {
    for binding in local.subscription_iam :
    "${binding.subscription}.${binding.role}" => binding
  }
  project      = local.project_id
  subscription = google_pubsub_subscription.default[each.value.subscription].name
  role         = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_pubsub_subscription_iam_binding" "bindings" {
  for_each     = local.subscription_iam_bindings
  project      = local.project_id
  subscription = google_pubsub_subscription.default[each.value.subscription].name
  role         = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_pubsub_subscription_iam_member" "members" {
  for_each     = local.subscription_iam_bindings_additive
  project      = local.project_id
  subscription = google_pubsub_subscription.default[each.value.subscription].name
  role         = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
